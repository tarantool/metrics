local Registry = {}
Registry.__index = Registry

function Registry.new()
    local obj = {}
    setmetatable(obj, Registry)
    obj:clear()
    return obj
end

function Registry:clear()
    self.collectors = {}
    self.callbacks = {}
    self.label_pairs = {}
end

function Registry:find(kind, name)
    for _, c in ipairs(self.collectors) do
        if c.name == name and c.kind == kind then
            return c
        end
    end
end

function Registry:find_or_create(class, name, ...)
    return self:find(class.kind, name) or self:register(class:new(name, ...))
end

local function is_empty(str)
    return str == nil or str == ''
end

function Registry:register(collector)
    assert(collector ~= nil, 'Collector is empty')
    assert(not is_empty(collector.name), "Collector''s name is empty")
    assert(not is_empty(collector.kind), "Collector''s kind is empty")
    if self:find(collector.kind, collector.name) then
        error('Already registered')
    end
    collector:set_registry(self)
    table.insert(self.collectors, collector)
    return collector
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

function Registry:set_labels(label_pairs)
    self.label_pairs = table.copy(label_pairs)
end

return Registry
