# Plugins

Plugins allow to use an unified interface to collect metrics without worrying about the way metrics export performed.
If you want to use another DB to store metrics data, you can use appropriate export plugin just by changing one line of code.


## Avaliable Plugins

- [Graphite](./graphite/README.md)
- [Prometheus](./prometheus/README.md)
- [Json](./json/README.md)
- [InfluxDB](./influxdb/README.md)

## Plugin-Specific API

We encourage you to use following methods **only when developing new plugin**.

#### `metrics.collectors()`
   Returns a list of created collectors.
   Designed to be used in exporters in favor of `metrics.collect()`.

#### `metrics.collect()`
    **NOTE**: You'll probably want to use `metrics.collectors()` instead.
    Equivalent to:
    ```lua
    for _, c in pairs(metrics.collectors()) do_
        for _, obs in ipairs(c:collect()) do
            ...  -- handle observation
        end_
    end
    ```

  Returns concatenation of `observation` objects across all collectors created.

  `observation` is a Lua table:
  ```lua
  {
    label_pairs: table,          -- `label_pairs` key-value table
    timestamp: ctype<uint64_t>,  -- current system time (in microseconds)
    value: number,               -- current value
    metric_name: string,         -- collector
  }
  ```

#### `metrics.invoke_callbacks()`
   Invokes function registered via `metrics.register_callback(<callback>)`
   Used in exporters.


## How To Write Your Custom Plugin?
Inside your main export function:

```lua
-- Invoke all callbacks registered via `metrics.register_callback(<callback-function>)`.
metrics.invoke_callbacks()

-- Loop over collectors
for _, c in pairs(metrics.collectors()) do
    ...

    -- Loop over instant observations in collector.
    for _, obs in pairs(c:collect()) do
        -- Export observation `obs`
        ...
    end

end
```
