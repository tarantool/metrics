[![Build Status](https://travis-ci.com/tarantool/metrics.svg?branch=master)](https://travis-ci.com/tarantool/metrics)

# Metrics

Metrics is a library to collect and expose [Tarantool](https://tarantool.io)-based applications metrics.

Library includes:
- four base metric collectors: Counter, Gauge, Histogram, Summary
- ready to use Tarantool stats collectors built on top of base collectors
- exporters to expose collected metrics in Prometheus, Graphite and generic JSON format
- module to integrate into Tarantool Cartridge based applications

## Table of contents

* [Installation](#installation)
* [Plugins export](#plugins-export)
* [Metric types](#metric-types)
  * [Counter](#counter)
  * [Gauge](#gauge)
  * [Histogram](#histogram)
  * [Summary](#summary)
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

## Metric types

There are four basic metric collectors available: Counter, Gauge, Summary and Histogram.
The exact semantics of each metric follows the [prometheus metric types](https://prometheus.io/docs/concepts/metric_types/).

### Counter

Counter is a cummulative metric which value can only be incremented or reset to zero on restart.
Counters are useful for accumulating number of events, e.g. requests processed, orders in e-shop. 
Counter is exposed as a single numerical value.

```lua
local metrics = require('metrics')

-- create a counter
local http_requests_total_counter = metrics.counter('http_requests_total')

-- somewhere in HTTP requests middleware:
http_requests_total_counter:inc(1, {method = 'GET'})
```

### Gauge

Gauge is a metric that represents a single numerical value that can be changed arbitrarily.
Gauges are useful for capturing a snapshot of the current state, e.g. CPU utilization, number of open connections.
Gauge is exposed as a single numerical value.

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

### Histogram

Histogram counts observed values into configurable buckets.
Histograms are useful for tracking request latencies, processing time.
Histogram is exposed as multiple numerical values: 
- the total count of observed events
- the total sum of observed values
- counters of observed events per bucket

```lua
local metrics = require('metrics')

-- create a histogram
local http_requests_latency_hist = metrics.histogram(
    'http_requests_latency', 'HTTP requests total', {2, 4, 6})

-- somewhere in the HTTP requests middleware:
local latency = math.random(1, 10)
http_requests_latency_hist:observe(latency)
```

### Summary

Summary aggregates observed values into configurable quantiles.
Summaries are useful as a service level indicator (e.g. SLAs, SLOs).
Summary is exposed as multiple numerical values:
- the total count of observed events
- the total sum of observed values
- number of observed events per quantile

```lua
local metrics = require('metrics')

-- create a summary
local http_requests_latency = metrics.summary(
    'http_requests_latency', 'HTTP requests total',
    {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01}
)

-- somewhere in the HTTP requests middleware:
local latency = math.random(1, 10)
http_requests_latency:observe(latency)
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
   [this](https://www.tarantool.io/en/doc/latest/book/cartridge/topics/clusterwide-config/#managing-role-specific-data)):
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
- Detailed information on [plugins](https://www.tarantool.io/en/doc/latest/book/monitoring/plugins)

## Contribution

Feel free to send Pull Requests.
For example, you can support new time series aggregation / manipulation functions
(but be sure to check if there are any Prometheus analogues to borrow API from).

## Credits

We would like to thank Prometheus for a great API that we brusquely borrowed.
