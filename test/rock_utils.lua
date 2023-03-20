local loaders_ok, loaders = pcall(require, 'internal.loaders')

local function traverse_rock(func, name)
    func(name, package.loaded[name])

    for subpkg_name, subpkg in pairs(package.loaded) do
        if subpkg_name:startswith(name .. '.') then
            func(subpkg_name, subpkg)
        end
    end
end

-- Package may have table cross-references.
local MAX_DEPTH = 8

-- Package functions contain useful debug info.
local function traverse_pkg_func(func, name, pkg, max_depth)
    max_depth = max_depth or MAX_DEPTH
    if max_depth <= 0 then
        return
    end

    if type(pkg) == 'function' then
        func(name, pkg)
        return
    end

    if type(pkg) ~= 'table' then
        return
    end

    for _, v in pairs(pkg) do
        traverse_pkg_func(func, name, v, max_depth - 1)
    end

    local mt = getmetatable(pkg)
    if mt ~= nil and mt.__call ~= nil then
        func(name, mt.__call)
    end
end

local function remove_loaded_pkg(name, _)
    package.loaded[name] = nil
end

local function remove_builtin_pkg(name, _)
    remove_loaded_pkg(name)
    if loaders_ok then
        loaders.builtin[name] = nil
    end
end

local function assert_nonbuiltin_func(pkg_name, func)
    local source = debug.getinfo(func).source
    assert(source:match('^@builtin') == nil,
           ("package %s is built-in, cleanup failed"):format(pkg_name))
end

local function assert_builtin_func(pkg_name, func)
    local source = debug.getinfo(func).source
    assert(source:match('^@builtin') ~= nil,
           ("package %s is external, built-in expected"):format(pkg_name))
end

local function assert_nonbuiltin_pkg(name, pkg)
    traverse_pkg_func(assert_nonbuiltin_func, name, pkg)
end

local function assert_builtin_pkg(name, pkg)
    traverse_pkg_func(assert_builtin_func, name, pkg)
end

local function remove_builtin_rock(name)
    traverse_rock(remove_builtin_pkg, name)
end

local function remove_loaded_rock(name)
    traverse_rock(remove_loaded_pkg, name)
end

local function remove_override_rock(name)
    loaders.override_builtin_disable()
    traverse_rock(remove_loaded_pkg, name)
end

local function assert_nonbuiltin_rock(name)
    require(name)
    traverse_rock(assert_nonbuiltin_pkg, name)
end

local function assert_builtin_rock(name)
    require(name)
    traverse_rock(assert_builtin_pkg, name)
end

return {
    assert_builtin = assert_builtin_rock,
    assert_nonbuiltin = assert_nonbuiltin_rock,
    remove_builtin = remove_builtin_rock,
    remove_loaded = remove_loaded_rock,
    remove_override = remove_override_rock,
}
