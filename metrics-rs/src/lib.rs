use std::collections::HashMap;
use mlua::prelude::*;

mod histogram_vec;
use histogram_vec::{LuaHistogramVec, LuaHistogramOpts};

// creates new HistogramVec with given label_names
fn new_histogram_vec(lua: &Lua, (opts, names):(LuaValue, LuaTable)) -> LuaResult<LuaHistogramVec> {
    let opts: LuaHistogramOpts = lua.from_value(opts)?;
    LuaHistogramVec::new(opts, names)
        .map_err(LuaError::external)
}

// gathers all metrics registered in default prometheus::Registry
fn gather(lua: &Lua, global_labels: Option<HashMap<String, String>>) -> LuaResult<LuaString> {
    let mfs = prometheus::gather();

    // if some global_labels given, add them to all metrics
    if let Some(ref hmap) = global_labels {
        let pairs: Vec<prometheus::proto::LabelPair> = hmap
        .iter()
        .map(|(k, v)| {
            let mut label = prometheus::proto::LabelPair::default();
            label.set_name(k.to_string());
            label.set_value(v.to_string());
            label
        })
        .collect();

        for mut m in mfs.clone().into_iter() {
            for metric in m.mut_metric().iter_mut() {
                let mut labels: Vec<_> = metric.take_label().into();
                labels.append(&mut pairs.clone());
                metric.set_label(labels.into());
            }
        }
    }

    let result = prometheus::TextEncoder::new()
        .encode_to_string(&mfs)
        .map_err(mlua::Error::external)?;

    lua.create_string(result)
}


#[mlua::lua_module]
pub fn metrics_rs(lua: &Lua) -> LuaResult<LuaTable> {
    let r = lua.create_table()?;

    r.set("new_histogram_vec", lua.create_function(new_histogram_vec)?)?;
    r.set("gather", lua.create_function(gather)?)?;

    Ok(r)
}
