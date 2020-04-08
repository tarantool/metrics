local Registry = {}
Registry.__index = Registry

function Registry.new()
    local obj = {}
    setmetatable(obj, Registry)

    obj.collectors = {}
    obj.callbacks = {}
    obj.label_pairs = {}
    return obj
end

function Registry:is_registered(collector)
    for _, c in ipairs(self.collectors) do
        if c.name == collector.name and c.kind == collector.kind then
            return true
        end
    end
    return false
end

local function is_empty(str)
    return str == nil or str == ''
end

function Registry:get_registered(collector)
    assert(collector ~= nil, 'Collector is empty')
    assert(not is_empty(collector.name), "Collector''s name is empty")
    assert(not is_empty(collector.kind), "Collector''s kind is empty")
    for _, c in ipairs(self.collectors) do
        if c.name == collector.name and c.kind == collector.kind then
            return c
        end
    end
    return nil
end

function Registry:register(collector)
    if self:is_registered(collector) then
        return
    end
    table.insert(self.collectors, collector)
end

function Registry:unregister(collector)
    for i, c in ipairs(self.collectors) do
        if c.name == collector.name and c.kind == collector.kind then
            table.remove(self.collectors, i)
        end
    end
end

function Registry:invoke_callbacks()
    for _, registered_callback in ipairs(self.callbacks) do
        registered_callback()
    end
end

function Registry:collect()
    local result = {}
    for _, collector in pairs(self.collectors) do
        for _, obs in ipairs(collector:collect()) do
            table.insert(result, obs)
        end
    end
    return result
end

function Registry:register_callback(callback)
    local found = false
    for _, registered_callback in ipairs(self.callbacks) do
        if registered_callback == callback then
            found = true
        end
    end
    if not found then
        table.insert(self.callbacks, callback)
    end
end

function Registry:instanceof(obj, mt)
    local metric = self:get_registered(obj)
    if metric == nil then
        metric = setmetatable(obj, mt)
        self:register(metric)
    end
    return metric
end

function Registry:set_labels(label_pairs)
    self.label_pairs = table.copy(label_pairs)
end

return Registry
