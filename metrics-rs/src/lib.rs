use std::collections::HashMap;

use mlua::prelude::*;
use prometheus::core::Collector;
use prometheus::proto::{self, MetricType};
use serde::{Deserialize, Serialize};

#[derive(Debug)]
pub struct LuaHistogramVec {
    pub histogram_vec: prometheus::HistogramVec,
    pub name: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct LuaHistogramOpts {
    pub name: String,
    pub help: String,
    pub buckets: Option<Vec<f64>>,
}

fn sample(lua: &Lua, output: LuaTable,
    name: &str,
    name_postfix: Option<&str>,
    mc: &proto::Metric,
    additional_label: Option<(&str, &str)>,
    global_label: &Option<HashMap<String, String>>,
    now: f64,
    value: f64
) -> LuaResult<LuaTable> {
	let mut name = name.to_string();
	if let Some(name_postfix) = name_postfix {
		name.push_str(name_postfix);
	}

	let label_pairs = lua.create_table_with_capacity(0,
        mc.get_label().len()
        +global_label.as_ref()
            .and_then(|x| Some(x.len())).unwrap_or_default()
    )?;
	for lp in mc.get_label() {
		label_pairs.set(lp.get_name().to_string(), lp.get_value().to_string())?;
	}
    if let Some(globals) = global_label {
        for (k,v) in globals.into_iter() {
            label_pairs.set(k.clone(), v.clone())?;
        }
    }
	if let Some(additional_label) = additional_label {
		label_pairs.set(additional_label.0.to_string(), additional_label.1.to_string())?;
	}

	let rec = lua.create_table_with_capacity(0, 4)?;
	rec.set("metric_name", name)?;
	rec.set("value", value)?;
	rec.set("timestamp", now)?;
	rec.set("label_pairs", label_pairs)?;
	output.push(rec)?;

	Ok(output)
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

        let hist = prometheus::HistogramVec::new(hopts, &label_names)
            .map_err(mlua::Error::external)?;

        Ok(Self { histogram_vec: hist, name })
    }

    pub fn observe(&self, value: f64, label_values: Option<Vec<String>>) -> LuaResult<()> {
        if let Some(lv) = label_values {
            let label_values = lv.iter().map(|s| &**s).collect::<Vec<&str>>();

            self.histogram_vec.get_metric_with_label_values(&label_values)
                .map_err(mlua::Error::external)?
                .observe(value);
        } else {
            self.histogram_vec.get_metric_with_label_values(&[])
                .map_err(mlua::Error::external)?
                .observe(value);
        }

        Ok(())
    }

    pub fn collect(&self, lua: &Lua, now: f64, global_labels: &Option<HashMap<String, String>>) -> LuaResult<LuaTable> {
        let mfs = self.histogram_vec.collect();

        let mut result = lua.create_table_with_capacity(mfs.len(), 0)?;

        for mf in mfs.iter() {
            if mf.get_metric().is_empty() {
                continue;
            }
            if mf.get_name().is_empty() {
                continue
            }

            if mf.get_field_type() != MetricType::HISTOGRAM {
                continue;
            }
            let metric_name = mf.get_name();
            for m in mf.get_metric() {
                let h = m.get_histogram();

                let mut inf_seen = false;
                for b in h.get_bucket() {
                    let upper_bound = b.get_upper_bound();
                    result = sample(lua, result,
                        metric_name,
                        Some("_bucket"),
                        m,
                        Some(("le", &upper_bound.to_string())),
                        global_labels,
                        now,
                        b.get_cumulative_count() as f64,
                    )?;

                    if upper_bound.is_sign_positive() && upper_bound.is_infinite() {
                        inf_seen = true;
                    }
                }

                if !inf_seen {
                    result = sample(lua, result,
                        metric_name,
                        Some("_bucket"),
                        m,
                        Some(("le", "+Inf")),
                        global_labels,
                        now,
                        h.get_sample_count() as f64,
                    )?;
                }

                result = sample(lua, result,
                    metric_name,
                    Some("_sum"),
                    m,
                    None,
                    global_labels,
                    now,
                    h.get_sample_sum(),
                )?;

                result = sample(lua, result,
                    metric_name,
                    Some("_count"),
                    m,
                    None,
                    global_labels,
                    now,
                    h.get_sample_count() as f64,
                )?;
            }
        }

        Ok(result)
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

        methods.add_method("observe", |_, this: &Self, (value, label_values):(f64, Option<Vec<String>>)| {
            this.observe(value, label_values)
        });

        methods.add_method("collect", |lua: &Lua, this: &Self, (now, global_labels): (f64, Option<HashMap<String,String>>)| {
            this.collect(lua, now, &global_labels)
        })
    }
}

pub fn new_collectors(lua: &Lua) -> LuaResult<LuaTable> {
    let r = lua.create_table()?;

    let new_histogram_vec = lua.create_function(|lua: &Lua, (opts, names):(LuaValue, LuaTable)| {
        let opts: LuaHistogramOpts = lua.from_value(opts)?;
        LuaHistogramVec::new(opts, names)
            .map_err(LuaError::external)
    })?;

    r.set("new_histogram_vec", new_histogram_vec)?;
    Ok(r)
}

#[mlua::lua_module]
pub fn metrics_rs(lua: &Lua) -> LuaResult<LuaTable> {
    let r = lua.create_table()?;

    let collectors = new_collectors(lua)?;
    r.set("collectors", collectors)?;

    Ok(r)
}
