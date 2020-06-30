[![Build Status](https://travis-ci.com/tarantool/metrics.svg?branch=master)](https://travis-ci.com/tarantool/metrics)
# Metrics

Metrics is a tool to collect, manipulate metrics timeseriess.  
Metrics uses a collection of primitives borrowed from Prometheus TSDB, which can be exported to any TSDB.

## Installation

```bash
cd ${PROJECT_ROOT}
tarantoolctl rocks install metrics
```

## Export Plugins
In order to easily export metrics to any TSDB you can use one of supported export plugins:

- [Graphite](./metrics/plugins/graphite/README.md)
- [Prometheus](./metrics/plugins/prometheus/README.md)
- [Json](./metrics/plugins/json/README.md)

or you can write your [custom plugin](./metrics/plugins/README.md) and use it.
Hopefully, plugins for other TSDBs will be supported soon.

## Examples

Below are the examples of using metrics primitives.

Note that this usage is independent of export-plugins such as Prometheus / Graphite / etc.
For documentation on plugins usage go to their respective README under `metrics/plugins/<name>/README.md`.

Using counters:
```lua
local metrics = require('metrics')

-- create counter
local http_requests_total_counter = metrics.counter('http_requests_total')

-- somewhere in HTTP requests middleware:
http_requests_total_counter:inc(1, {method = 'GET'})
```

Using gauges:
```lua
local metrics = require('metrics')

-- create gauge
local cpu_usage_gauge = metrics.gauge('cpu_usage', 'CPU usage')

-- register a lazy gauge value update
-- this will be called whenever the export is invoked in any plugins.
metrics.register_callback(function()
    local current_cpu_usage = math.random()
    cpu_usage_gauge:set(current_cpu_usage, {app = 'tarantool'})
end)
```

Using histograms:
```lua
local metrics = require('metrics')

-- create histogram
local http_requests_latency_hist = metrics.histogram(
    'http_requests_latency', 'HTTP requests total', {2, 4, 6})

-- somewhere in HTTP requests middleware:
local latency = math.random(1, 10)
http_requests_latency_hist:observe(latency)
```


## API

### Collectors

The application using `metrics` module has 3 primitives (called collectors) at its disposal:
- Counter
- Gauge
- Histogram

Collectors represent an observation or a few that are changing over time.

### Labels

All collectors support providing `label_pairs` on data modification.
Labels are basically a metainfo you associate with a metric in format of key-value pairs.
See tags in Graphite and labels in Prometheus.

Labels are used to differentiate the characteristics of a thing being measured.
For example, in metric associated with http total # of requests you can use methods and statuses label pairs:
```lua
    http_requests_total_counter:inc(1, {method = 'POST', status = '200'})
```

You don't have to predefine a set of labels in advance.

Using labels on your metrics allows you to later derive new timeserieses (visualize their graphs)
by specifying conditions on label values. In above example, we could derive a timeserieses:
  1. total # of requests over time with method = "POST" (and any status).
  2. total # of requests over time with status = 500 (and any method).

You can also set global labels by calling `metrics.set_global_labels({ label = value, ...})`.

------------------------------------------------------------------------


```lua
-- importing metrics
metrics = require('metrics')
```

#### `metrics.enable_default_metrics()`
  Enables default metrics collections. 
  Collects tarantool metrics, ported from https://github.com/tarantool/stat

#### `metrics.set_global_labels(label_pairs)`
  Set global labels that will be added to every observation.
  * `label_pairs` Table containing label names as string keys, label values as values (table).

  Global labels applied only on metrics collect and have no effect on observations' storage.
  Global labels can be changed along the way.
  Observation `label_pairs` are prior to global labels: if you pass `label_pairs` to observation method with the same key as some global label, the method argument value will be used.

#### `client_obj.register_callback(callback)`
  Registers a function `callback` which will be called right
  before metrics collection on plugin export.
  * `callback` Function which takes no parameters.

  Most common usage is for gauge metrics updates.

### Creating and Using Collectors

#### Counter

#### `metrics.counter(name, help)`
  Registers a new counter.
  Returns Counter object.
  * `name` Collector name (string). Must be unique.
  * `help` (optional) Help description (string).

#### `counter_obj:inc(num, label_pairs)`
  Increments observation under `label_pairs`. If `label_pairs` didn't exist before - this creates it.
  * `num` Increase value (number).
  * `label_pairs` Table containing label names as keys, label values as values (table).

#### `counter_obj:collect()`
  Returns array of `observation` objects for given counter.
  `observation` is a Lua table:
  ```lua
  {
    label_pairs: table,          -- `label_pairs` key-value table
    timestamp: ctype<uint64_t>,  -- current system time (in microseconds)
    value: number,               -- current value
    metric_name: string,         -- collector
  }
  ```

#### Gauge

#### `metrics.gauge(name, help)`
  Registers a new gauge.
  Returns Gauge object.
  * `name` Collector name (string). Must be unique.
  * `help` (optional) Help description (string).

#### `gauge_obj:inc(num, label_pairs)`
  Same as Counter `inc()`.

#### `gauge_obj:dec(num, label_pairs)`
  Same as `inc()`, but decreases the observation.

#### `gauge_obj:set(num, label_pairs)`
  Same as `inc()`, but sets the observation.

#### `gauge_obj:collect()`
  Returns array of `observation` objects for given gauge.
  For `observation` description see `counter_obj:collect()` section.

#### Histogram

#### `metrics.histogram(name, help, buckets)`
  Registers a new histogram.
  Returns Histogram object.
  * `name` Collector name (string). Must be unique.
  * `help` (optional) Help description (string).
  * `buckets` Histogram buckets (array of positive sorted numbers). `INF` bucket is added automatically. Default is 
{.005, .01, .025, .05, .075, .1, .25, .5, .75, 1.0, 2.5, 5.0, 7.5, 10.0, INF}.

  **NOTE**: The histogram is just a set of collectors:
  * `name .. "_sum"` - Counter holding sum of added observations. Has only empty labelset.
  * `name .. "_count"` - Counter holding number of added observations. Has only empty labelset.
  * `name .. "_bucket"` - Counter holding all bucket sizes under label `le` (low or equal). So to access specific bucket `x` (`x` is a number), you should specify value `x` for label `le`.

#### `histogram_obj:observe(num, label_pairs)`
  Records a new value in histogram. This increments all buckets sizes under labels `le` >= `num` and labels matching `label_pairs`.
  * `num` Value to put in histogram (number).
  * `label_pairs` Table containing label names as keys, label values as values (table). New value is observed by all internal counters with these labels specified.

#### `histogram_obj:observe_latency(label_pairs, fn, ...)`
  Measure latency of function call
  * `label_pairs` either table with labels or function to generate labels
  * `fn` function for pcall to instrument
  * `...` args for function `fn`

  Return results of fn call or reraise error

#### `histogram_obj:collect()`
  Returns concatenation of `counter_obj:collect()` across all internal counters
  of `histogram_obj`.  
  For `observation` description see `counter_obj:collect()` section.

#### Average
  Can be used only as HTTP statistics collector (described below) and cannot be built explicitly.

#### `average_obj:collect()`
  Returns list of two observations: 
  * `name .. "_avg"` - average value of observations for the observing period (time from previous collect call to now),
  * `name .. "_count"` - observation count for the same period.
  For `observation` description see `counter_obj:collect()` section.

### Collecting HTTP requests latency statistics

`metrics` also provides a middleware for monitoring HTTP (set by [http](https://github.com/tarantool/http) module) latency statistics.

```
-- importing submodule
http_middleware = metrics.http_middleware
```

#### `http_middleware.configure_default_collector(type_name, name, help)`
  Registers collector for middleware and sets it as default.
  * `type_name` Collector type (string): "histogram" or "average". Default is "histogram".
  * `name` Collector name (string). Default is "http_server_request_latency".
  * `help` (optional) Help description (string). Default is "HTTP Server Request Latency".

  If collector with the same type and name already exists in registry, throws an error.

#### `http_middleware.build_default_collector(type_name, name, help)`
  Registers collector for middleware and returns it.
  * `type_name` Collector type (string): "histogram" or "average". Default is "histogram".
  * `name` Collector name (string). Default is "http_server_request_latency".
  * `help` (optional) Help description (string). Default is "HTTP Server Request Latency".

  If collector with the same type and name already exists in registry, throws an error.

#### `http_middleware.set_default_collector(collector)`
  Sets default collector.
  * `collector` Middleware collector object.

#### `http_middleware.get_default_collector()`
  Returns default collector.
  If default collector hasn't been set yet, registers it (with default `http_middleware.build_default_collector(...)` parameters) and sets it as default.

#### `http_middleware.v1(handler, collector)`
  Latency measure wrap-up for HTTP ver. 1.x.x handler. Returns wrapped handler.
  * `handler` Handler function.
  * `collector` Middleware collector object. If not set, uses default collector (like in `http_middleware.get_default_collector()`).

  Usage:
  ```
  httpd:route(route, http_middleware.v1(request_handler, collector))
  ```

  For more detailed example see [example/HTTP/latency_v1.lua](./example/HTTP/latency_v1.lua).

#### `http_middleware.v2(collector)`
  Returns latency measure middleware for HTTP ver. 2.x.x.
  * `collector` Middleware collector object. If not set, uses default collector (like in `http_middleware.get_default_collector()`).

  Usage:
  ```
  router = require('http.router').new()

  router:route(route, request_handler)
  router:use(http_middleware.v2(collector), {name = 'http_instrumentation'}) -- Second argument is optional, see HTTP docs
  ```

  For more detailed example see [example/HTTP/latency_v2.lua](./example/HTTP/latency_v2.lua).

## CPU usage metrics

### Collected metrics example
```
# HELP tnt_cpu_total Host CPU time
# TYPE tnt_cpu_total gauge
tnt_cpu_total 15006759
# HELP tnt_cpu_thread Tarantool thread cpu time
# TYPE tnt_cpu_thread gauge
tnt_cpu_thread{thread_name="coio",file_name="init.lua",thread_pid="699",kind="system"} 160
tnt_cpu_thread{thread_name="tarantool",file_name="init.lua",thread_pid="1",kind="user"} 949
tnt_cpu_thread{thread_name="tarantool",file_name="init.lua",thread_pid="1",kind="system"} 920
tnt_cpu_thread{thread_name="coio",file_name="init.lua",thread_pid="11",kind="user"} 79
tnt_cpu_thread{thread_name="coio",file_name="init.lua",thread_pid="699",kind="user"} 44
tnt_cpu_thread{thread_name="coio",file_name="init.lua",thread_pid="11",kind="system"} 294
```

### Prometheus query aggregated by thread name
```promql
sum by (thread_name) (idelta(tnt_cpu_thread[$__interval]))
  / scalar(idelta(tnt_cpu_total[$__interval]) / tnt_cpu_count)
```

## CONTRIBUTION

Feel free to send Pull Requests. E.g. you can support new timeseries aggregation / manipulation functions (but be sure to check if there are any Prometheus analogues to borrow API from).

## CREDIT

We would like to thank Prometheus for a great API that we brusquely borrowed.
