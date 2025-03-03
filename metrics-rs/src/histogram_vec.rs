use std::collections::HashMap;

use mlua::prelude::*;
use prometheus::core::Collector;
use prometheus::proto;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct LuaHistogramOpts {
    pub name: String,
    pub help: String,
    pub buckets: Option<Vec<f64>>,
}

#[derive(Debug)]
pub struct LuaHistogramVec {
    pub histogram_vec: Box<prometheus::HistogramVec>,
    pub name: String,
}

impl LuaHistogramVec {
    pub fn new(opts: LuaHistogramOpts, label_names: LuaTable) -> LuaResult<Self> {
        let name = opts.name.clone();
        let mut hopts = prometheus::HistogramOpts::new(opts.name, opts.help);
        if let Some(buckets) = opts.buckets {
            hopts = hopts.buckets(buckets);
        }

        let label_names: Vec<String> = label_names.pairs()
            .map(|kv| -> LuaResult<String> {
                let (_,v):(LuaValue, LuaString) = kv?;
                Ok(v.to_string_lossy())
            })
            .collect::<LuaResult<Vec<_>>>()?;

        let label_names = label_names.iter().map(|s| &**s).collect::<Vec<&str>>();

        let hist = Box::new(prometheus::HistogramVec::new(hopts, &label_names)
            .map_err(mlua::Error::external)?
        );

        prometheus::register(hist.clone())
            .map_err(mlua::Error::external)?;

        Ok(Self { histogram_vec: hist, name })
    }

    pub fn observe(&self, value: f64, label_values: Option<Vec<String>>) -> LuaResult<()> {
        if let Some(lv) = label_values {
            let label_values = lv.iter().map(|s| &**s).collect::<Vec<&str>>();

            self.histogram_vec
                .get_metric_with_label_values(&label_values)
                .map_err(mlua::Error::external)?
                .observe(value);
        } else {
            self.histogram_vec.get_metric_with_label_values(&[])
                .map_err(mlua::Error::external)?
                .observe(value);
        }

        Ok(())
    }

    pub fn remove(&mut self, lv: Vec<String>) -> LuaResult<()> {
        let label_values = lv.iter().map(|s| &**s).collect::<Vec<&str>>();

        self.histogram_vec.remove_label_values(&label_values)
            .map_err(mlua::Error::external)
    }

    pub fn collect_str(&self, lua: &Lua) -> LuaResult<LuaString> {
        let mfs = self.histogram_vec.collect();

        let result = prometheus::TextEncoder::new()
            .encode_to_string(&mfs)
            .map_err(mlua::Error::external)?;

        lua.create_string(result)
    }

    pub fn collect(&self, lua: &Lua, global_values: Option<HashMap<String,String>>) -> LuaResult<LuaTable> {
        let result = lua.create_table()?;
        let mfs = self.histogram_vec.collect();

        let pairs: Option<Vec<proto::LabelPair>> = global_values.map(|ref hmap|
            hmap
                .iter()
                .map(|(k, v)| {
                    let mut label = proto::LabelPair::default();
                    label.set_name(k.to_string());
                    label.set_value(v.to_string());
                    label
                })
                .collect()
        );

        for mut mf in mfs.into_iter() {
            if mf.get_metric().is_empty() {
                continue;
            }

            let metric_name = mf.get_name();
            let lbucket_name = lua.create_string(metric_name.to_string() + "_bucket")?;
            let lsum_name = lua.create_string(metric_name.to_string() + "_sum")?;
            let lcount_name = lua.create_string(metric_name.to_string() + "_count")?;

            // append global labels if needed
            if let Some(pairs) = &pairs {
                for metric in mf.mut_metric().iter_mut() {
                    let mut labels: Vec<_> = metric.take_label().into();
                    labels.append(&mut pairs.clone());
                    metric.set_label(labels.into());
                }
            }

            for metric in mf.get_metric().iter() {
                let time = metric.get_timestamp_ms() * 1000;

                // we convert labels into pair of lua strings
                let mut labels: Vec<_> = Vec::with_capacity(metric.get_label().len());

                for pair in metric.get_label().iter() {
                    let k = pair.get_name();
                    let v = pair.get_value();

                    let k = lua.create_string(&k)?;
                    let v = lua.create_string(&v)?;

                    labels.push((k,v));
                }

                let h = metric.get_histogram();

                for b in h.get_bucket() {
                    let lmetric = lua.create_table_with_capacity(0, 4)?;
                    lmetric.set("metric_name", &lbucket_name)?;
                    lmetric.set("value", b.get_cumulative_count())?;
                    lmetric.set("timestamp", time)?;

                    // upper_bound should be used as label
                    let upper_bound = b.get_upper_bound();

                    let blabels = lua.create_table()?;
                    for pair in labels.iter() { blabels.set(&pair.0, &pair.1)? }
                    blabels.set("le", upper_bound)?;

                    lmetric.set("labels", blabels)?;
                    result.raw_push(lmetric)?;
                }

                let blabels = lua.create_table()?;
                for pair in labels.iter() { blabels.set(&pair.0, &pair.1)? }

                let lmetric = lua.create_table_with_capacity(0, 4)?;
                lmetric.set("value", h.get_sample_count())?;
                lmetric.set("metric_name", &lcount_name)?;
                lmetric.set("timestamp", time)?;
                lmetric.set("labels", &blabels)?; // blabels are shared between _count and _sum
                result.raw_push(lmetric)?;

                let lmetric = lua.create_table_with_capacity(0, 4)?;
                lmetric.set("metric_name", &lsum_name)?;
                lmetric.set("timestamp", time)?;
                lmetric.set("value", h.get_sample_sum())?;
                lmetric.set("labels", &blabels)?; // blabels are shared between _count and _sum
                result.raw_push(lmetric)?;
            }
        }

        Ok(result)
    }
}

impl Drop for LuaHistogramVec {
    fn drop(&mut self) {
        let r = prometheus::unregister(self.histogram_vec.clone());
        if let Some(err) = r.err() {
            eprintln!("Failed to unregister LuaHistogramVec: {}: {}", self.name, err);
        }
    }
}

impl LuaUserData for LuaHistogramVec {
    fn add_methods<M: LuaUserDataMethods<Self>>(methods: &mut M) {
        let tostring = |lua: &Lua, this: &LuaHistogramVec, ()| -> LuaResult<LuaString> {
            let msg = format!("HistogramVec<{}>", this.name);
            let s = lua.create_string(msg)?;
            Ok(s)
        };
        methods.add_meta_method("__serialize", tostring);
        methods.add_meta_method("__tostring", tostring);

        methods.add_method("collect_str", |lua: &Lua, this: &Self, ():()| {
            this.collect_str(lua)
        });

        methods.add_method("collect", |lua: &Lua, this: &Self, global_values: Option<HashMap<String,String>>| {
            this.collect(lua, global_values)
        });

        methods.add_method_mut("remove", |_, this: &mut Self, label_values: _| {
            this.remove(label_values)
        });

        methods.add_method("observe", |_, this: &Self, (value, label_values):(_, _)| {
            this.observe(value, label_values)
        });
    }
}
