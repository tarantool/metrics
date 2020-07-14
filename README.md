[![Build Status](https://travis-ci.com/tarantool/metrics.svg?branch=master)](https://travis-ci.com/tarantool/metrics)
# Metrics

Metrics is a tool to collect and manipulate metrics time series.
Metrics uses a collection of primitives borrowed from the Prometheus TSDB,
which can be exported to any TSDB.

Contents:

* [Installation](#installation)
* [Plugins export](#plugins-export)
* [Examples](#examples)
* [Next steps](#next-steps)
* [Cartridge role](#cartridge-role)
* [Contribution](#contribution)
* [Credits](#credits)

## Installation

```bash
cd ${PROJECT_ROOT}
tarantoolctl rocks install metrics
```

## Plugins export

In order to easily export metrics to any TSDB, you can use one of the supported
export plugins:

- [Graphite](https://www.tarantool.io/en/doc/latest/book/monitoring/plugins/#graphite)
- [Prometheus](https://www.tarantool.io/en/doc/latest/book/monitoring/plugins/#prometheus)
- [Json](https://www.tarantool.io/en/doc/latest/book/monitoring/plugins/#json)

or you can write your [custom plugin](https://www.tarantool.io/en/doc/latest/book/monitoring/plugins/#writing-custom-plugins) and use it.
Hopefully, plugins for other TSDBs will be supported soon.

## Examples

Below are examples of using metrics primitives.

Note that this usage is independent of export-plugins such as
Prometheus / Graphite / etc.
For documentation on plugins usage, see [this](https://www.tarantool.io/en/doc/latest/book/monitoring/plugins).

Using counters:
```lua
local metrics = require('metrics')

-- create a counter
local http_requests_total_counter = metrics.counter('http_requests_total')

-- somewhere in HTTP requests middleware:
http_requests_total_counter:inc(1, {method = 'GET'})
```

Using gauges:
```lua
local metrics = require('metrics')

-- create a gauge
local cpu_usage_gauge = metrics.gauge('cpu_usage', 'CPU usage')

-- register a lazy gauge value update
-- this will be called whenever the export is invoked in any plugins
metrics.register_callback(function()
    local current_cpu_usage = math.random()
    cpu_usage_gauge:set(current_cpu_usage, {app = 'tarantool'})
end)
```

Using histograms:
```lua
local metrics = require('metrics')

-- create a histogram
local http_requests_latency_hist = metrics.histogram(
    'http_requests_latency', 'HTTP requests total', {2, 4, 6})

-- somewhere in the HTTP requests middleware:
local latency = math.random(1, 10)
http_requests_latency_hist:observe(latency)
```

## Cartridge role

`cartridge.roles.metrics` is a role for
[tarantool/cartridge](https://github.com/tarantool/cartridge).
It allows to use default metrics in a Cartridge application and manage them
via configuration.

### Usage

1. Add the `metrics` package to dependencies in the `.rockspec` file.
   Make sure that you are using version 0.3.0 or higher.
   ```lua
   dependencies = {
       ...
       'metrics >= 0.3.0-1',
       ...
   }
   ```

2. Add `cartridge.roles.metrics` to the roles list in `cartridge.cfg`
   in your entry-point file (e.g. `init.lua`).
   ```lua
   local ok, err = cartridge.cfg({
       ...
       roles = {
           ...
           'cartridge.roles.metrics',
           ...
       },
   })
   ```
3. After role initialization, default metrics will be enabled and the global
   label 'alias' will be set. If you need to use the functionality of any metrics
   package, you may get it as a Cartridge service and use it like a regular
   package after `require`:
   ```lua
   local cartridge = require('cartridge')
   local metrics = cartridge.service_get('metrics')
   ```

4. To view metrics via API endpoints, use the following configuration
   (to learn more about Cartridge configuration, see
   [this](https://www.tarantool.io/en/doc/2.3/book/cartridge/topics/clusterwide-config/#managing-role-specific-data)):
   ```yaml
   metrics:
     export:
       - path: '/path_for_json_metrics'
         format: 'json'
       - path: '/path_for_prometheus_metrics'
         format: 'prometheus'
   ```

You can add several entry points of the same format by different paths, like this:
```yaml
metrics:
  export:
    - path: '/path_for_json_metrics'
      format: 'json'
    - path: '/another_path_for_json_metrics'
      format: 'json'
```

## Next steps

See:

- A more detailed [getting started guide](https://www.tarantool.io/en/doc/latest/book/monitoring/monitoring-getting-started)
- Metrics [API reference](https://www.tarantool.io/en/doc/latest/book/monitoring/metrics-api-reference)
- How to use the [Grafana dashboard](https://www.tarantool.io/en/doc/latest/book/monitoring/monitoring-getting-started/#grafana-dashboard) with `tarantool/metrics`
- Detailed information on [plugins](https://www.tarantool.io/en/doc/latest/book/monitoring/plugins)

## Contribution

Feel free to send Pull Requests.
For example, you can support new time series aggregation / manipulation functions
(but be sure to check if there are any Prometheus analogues to borrow API from).

## Credits

We would like to thank Prometheus for a great API that we brusquely borrowed.
