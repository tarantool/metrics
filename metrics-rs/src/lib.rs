use std::collections::HashMap;
use mlua::prelude::*;

mod registry;
mod histogram_vec;
use histogram_vec::{LuaHistogramVec, LuaHistogramOpts};

// creates new HistogramVec with given label_names
fn new_histogram_vec(lua: &Lua, (opts, names):(LuaValue, LuaTable)) -> LuaResult<LuaHistogramVec> {
    let opts: LuaHistogramOpts = lua.from_value(opts)?;
    LuaHistogramVec::new(opts, names)
        .map_err(LuaError::external)
}

// gathers all metrics registered in default prometheus::Registry
fn gather(lua: &Lua, ():()) -> LuaResult<LuaString> {
    let mfs = registry::gather();

    let result = prometheus::TextEncoder::new()
        .encode_to_string(&mfs)
        .map_err(mlua::Error::external)?;

    lua.create_string(result)
}

fn set_labels(_: &Lua, global_labels: HashMap<String, String>) -> LuaResult<()> {
    registry::set_labels(global_labels);
    Ok(())
}

#[mlua::lua_module]
pub fn metrics_rs(lua: &Lua) -> LuaResult<LuaTable> {
    let r = lua.create_table()?;

    r.set("new_histogram_vec", lua.create_function(new_histogram_vec)?)?;
    r.set("gather", lua.create_function(gather)?)?;
    r.set("set_labels", lua.create_function(set_labels)?)?;

    Ok(r)
}
