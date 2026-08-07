---@alias metrics.registry.filter {include_all: boolean, include: string[], exclude_all: boolean, exclude: string[]}

---@class metrics.registry
---@field collectors table<string, metrics.collector>
---@field callbacks table<function, metrics.metainfo>
---@field label_pairs metrics.label_pairs
---@field filter metrics.registry.filter

local Registry = {}
Registry.__index = Registry

--- Create a new registry.
---@return metrics.registry
function Registry.new()
    local obj = setmetatable({}, Registry)
    obj:clear()
    return obj
end

--- Clear all collectors, callbacks, and labels from the registry.
function Registry:clear()
    self.collectors = {}
    self.callbacks = {}
    self.label_pairs = {}
    self:reset_filter()
end

function Registry:reset_filter()
    self.filter = {
        include_all = true,
        include = {},
        exclude_all = false,
        exclude = {},
    }
end

--- Find a collector in the registry.
---@param kind string
---@param name string
---@return metrics.collector|nil
function Registry:find(kind, name)
    return self.collectors[name .. kind]
end

---@param class metrics.collector
---@param name string
---@vararg any
---@return metrics.collector
function Registry:find_or_create(class, name, ...)
    return self:find(class.kind, name) or self:register(class:new(name, ...))
end

local function is_empty(str)
    return str == nil or str == ''
end

---@param collector metrics.collector
---@return metrics.collector
function Registry:register(collector)
    assert(collector ~= nil, 'Collector is empty')
    assert(not is_empty(collector.name), "Collector's name is empty")
    assert(not is_empty(collector.kind), "Collector's kind is empty")
    if self:find(collector.kind, collector.name) then
        error('Already registered')
    end
    collector:set_registry(self)
    self.collectors[collector.name .. collector.kind] = collector
    return collector
end

--- Remove a collector from the registry.
---@param collector metrics.collector
function Registry:unregister(collector)
    self.collectors[collector.name .. collector.kind] = nil
end

local function has_prefix(s, prefix)
    return s:startswith(prefix .. '.')
end

local function selector_matches(selector, rules)
    if selector == nil then
        return false
    end

    for _, rule in ipairs(rules) do
        if selector == rule or has_prefix(selector, rule) then
            return true
        end
    end

    return false
end

local function item_selector(item)
    if item == nil then
        return nil
    end

    local metainfo = item.metainfo or item
    return metainfo.selector or item.name
end

---@param item metrics.collector|metrics.metainfo|nil
---@return boolean
function Registry:is_enabled(item)
    --- @type { include_all: boolean, include: table, exclude_all: boolean, exclude: table }
    local filter = self.filter
    local metainfo = item and (item.metainfo or item)
    if metainfo and metainfo.default then
        return not filter.exclude_all
    end

    local selector = item_selector(item)

    local included = filter.include_all or
                     selector_matches(selector, filter.include)
    if not included then
        return false
    end

    if filter.exclude_all or selector_matches(selector, filter.exclude) then
        return false
    end

    return true
end

---@return table<string, metrics.collector>
function Registry:filtered_collectors()
    local collectors = {}

    for key, collector in pairs(self.collectors) do
        if self:is_enabled(collector) then
            collectors[key] = collector
        end
    end

    return collectors
end

--- Invoke all registered callbacks.
function Registry:invoke_callbacks()
    for registered_callback, metainfo in pairs(self.callbacks) do
        if self:is_enabled(metainfo) then
            registered_callback()
        end
    end
end

--- Collect observations from each collector.
---@return metrics.observation[]
function Registry:collect()
    local result = {}
    for _, collector in pairs(self:filtered_collectors()) do
        for _, obs in ipairs(collector:collect()) do
            table.insert(result, obs)
        end
    end
    return result
end

--- Register a callback that is called right before metric collection.
---@param callback function
---@param metainfo metrics.metainfo?
function Registry:register_callback(callback, metainfo)
    self.callbacks[callback] = table.copy(metainfo) or {}
end

--- Unregister a callback.
---@param callback function
function Registry:unregister_callback(callback)
    self.callbacks[callback] = nil
end

--- Set global labels applied to every observation.
---@param label_pairs metrics.label_pairs
function Registry:set_labels(label_pairs)
    self.label_pairs = table.copy(label_pairs)
end

local function normalize_filter_side(value, default)
    if value == nil then
        return default
    end

    if type(value) == 'string' then
        if value ~= 'all' and value ~= 'none' then
            error("Metric selector filter string must be 'all' or 'none'")
        end
        return {
            all = value == 'all',
            selectors = {},
        }
    end

    if type(value) ~= 'table' then
        error("Metric selector filter must be 'all', 'none', or an array of " ..
              "selector objects")
    end

    local selectors = {}
    for _, item in ipairs(value) do
        if type(item) ~= 'table' or type(item.selector) ~= 'string' or
           item.selector == '' then
            error('Metric selector filter item must be a table with a ' ..
                  'non-empty selector field')
        end
        table.insert(selectors, item.selector)
    end

    return {
        all = false,
        selectors = selectors,
    }
end

--- Set a runtime filter for collectors and callbacks by metric selectors.
---@param include string|table|nil
---@param exclude string|table|nil
function Registry:set_filter(include, exclude)
    local include_filter = normalize_filter_side(include, {
        all = true,
        selectors = {},
    })
    local exclude_filter = normalize_filter_side(exclude, {
        all = false,
        selectors = {},
    })

    self.filter = {
        include_all = include_filter.all,
        include = include_filter.selectors,
        exclude_all = exclude_filter.all,
        exclude = exclude_filter.selectors,
    }
end

return Registry
