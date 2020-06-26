[![Build Status](https://travis-ci.com/tarantool/metrics.svg?branch=master)](https://travis-ci.com/tarantool/metrics)
# Metrics

Metrics is a tool to collect and manipulate metrics time series.
Metrics uses a collection of primitives borrowed from the Prometheus TSDB,
which can be exported to any TSDB.

Contents:

* [Installation](#installation)
* [Plugins export](#plugins-export)
* [Examples](#examples)
* [API](#api)
* [CPU usage metrics](#cpu-usage-metrics)
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

- [Graphite](./metrics/plugins/graphite/README.md)
- [Prometheus](./metrics/plugins/prometheus/README.md)
- [Json](./metrics/plugins/json/README.md)

or you can write your [custom plugin](./metrics/plugins/README.md) and use it.
Hopefully, plugins for other TSDBs will be supported soon.

## Examples

Below are examples of using metrics primitives.

Note that this usage is independent of export-plugins such as
Prometheus / Graphite / etc.
For documentation on plugins usage, see their respective README files under
`metrics/plugins/<name>/README.md`.

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

## API

### Collectors

An application using the `metrics` module has 3 primitives (called collectors)
at its disposal:
- Counter
- Gauge
- Histogram

A collector represents one or more observations that are changing over time.

### Labels

All collectors support providing `label_pairs` on data modification.
Labels are basically a metainfo that you associate with a metric in the format
of key-value pairs.
See tags in Graphite and labels in Prometheus.

Labels are used to differentiate the characteristics of a thing being measured.
For example, in a metric associated with the total number of http requests, you
can use methods and statuses label pairs:
```lua
    http_requests_total_counter:inc(1, {method = 'POST', status = '200'})
```

You don't have to predefine labels in advance.

Using labels on your metrics allows you to later derive new time series
(visualize their graphs) by specifying conditions on label values.
In the example above, we could derive these time series:
  1. total # of requests over time with method = "POST" (and any status).
  2. total # of requests over time with status = 500 (and any method).

You can also set global labels by calling
`metrics.set_global_labels({ label = value, ...})`.

------------------------------------------------------------------------

#### Importing the metrics module

```lua
-- importing metrics
metrics = require('metrics')
```

#### `metrics.enable_default_metrics()`
  Enables default metrics collections.
  Collects tarantool metrics, ported from https://github.com/tarantool/stat

#### `metrics.set_global_labels(label_pairs)`
  Set global labels that will be added to every observation.

  Parameters:
  * `label_pairs` table contains label names as string keys, label values as values (table).

  Global labels are applied only on metrics collection and have no effect on
  how observations are stored.
  Global labels can be changed on the fly.
  Observation `label_pairs` have priority over global labels:
  if you pass `label_pairs` to an observation method with the same key as
  some global label, the method argument value will be used.

#### `client_obj.register_callback(callback)`
  Registers a function `callback` which will be called right
  before metrics collection on plugin export.

  Parameters:
  * `callback` function which takes no parameters.

  Most common usage is for gauge metrics updates.

### Creating and using collectors

#### Counter

#### `metrics.counter(name, help)`
  Registers a new counter.
  Returns a Counter object.

  Parameters:
  * `name` a Collector name (string). Must be unique.
  * `help` (optional) help description (string).

#### `counter_obj:inc(num, label_pairs)`
  Increments the observation under `label_pairs`.
  If `label_pairs` didn't exist before, this creates it.

Parameters:
  * `num` the value to increase by (number).
  * `label_pairs` a table containing label names as keys, label values as values (table).

#### `counter_obj:collect()`
  Returns an array of `observation` objects for a given counter.
  `observation` is a Lua table:
  ```lua
  {
    label_pairs: table,          -- `label_pairs` key-value table
    timestamp: ctype<uint64_t>,  -- current system time (in microseconds)
    value: number,               -- current value
    metric_name: string,         -- collector
  }
  ```

### Gauge

#### `metrics.gauge(name, help)`
  Registers a new gauge.
  Returns a Gauge object.

  Parameters:
  * `name` a collector name (string). Must be unique.
  * `help` (optional) help description (string).

#### `gauge_obj:inc(num, label_pairs)`
  Same as Counter `inc()`.

#### `gauge_obj:dec(num, label_pairs)`
  Same as `inc()`, but decreases the observation.

#### `gauge_obj:set(num, label_pairs)`
  Same as `inc()`, but sets the observation.

#### `gauge_obj:collect()`
  Returns an array of `observation` objects for a given gauge.
  For `observation` description, see the `counter_obj:collect()` section.

#### Histogram

#### `metrics.histogram(name, help, buckets)`
  Registers a new histogram.
  Returns a Histogram object.

  Parameters:
  * `name` a collector name (string). Must be unique.
  * `help` (optional) help description (string).
  * `buckets` histogram buckets (an array of sorted positive numbers).
    Infinity bucket (`INF`) is appended automatically. Default is
    {.005, .01, .025, .05, .075, .1, .25, .5, .75, 1.0, 2.5, 5.0, 7.5, 10.0, INF}.

  **NOTE**: The histogram is just a set of collectors:
  * `name .. "_sum"` - a counter holding the sum of added observations.
    Has only an empty labelset.
  * `name .. "_count"` - a counter holding number of added observations.
    Has only an empty labelset.
  * `name .. "_bucket"` - a counter holding all bucket sizes under the label
    `le` (low or equal). So to access a specific bucket `x` (`x` is a number),
    you should specify the value `x` for the label `le`.

#### `histogram_obj:observe(num, label_pairs)`
  Records a new value in the histogram.
  This increments all buckets sizes under labels `le` >= `num` and labels
  matching `label_pairs`.

Parameters:
  * `num` the value to put in the histogram (number).
  * `label_pairs` a table containing label names as keys, label values as values
    (table). New value is observed by all internal counters with these labels specified.

#### `histogram_obj:collect()`
  Returns a concatenation of `counter_obj:collect()` across all internal counters
  of `histogram_obj`.
  For `observation` description, see `counter_obj:collect()` section.

#### Average
  Can be used only as HTTP statistics collector (described below) and cannot be
  built explicitly.

#### `average_obj:collect()`
  Returns a list of two observations:
  * `name .. "_avg"` - the average value of observations for the observing period
    (time since the previous collect call till now),
  * `name .. "_count"` - the observation count for the same period.
  For `observation` description, see `counter_obj:collect()` section.

### Collecting HTTP requests latency statistics

`metrics` also provides a middleware for monitoring HTTP
(set by the [http](https://github.com/tarantool/http) module) latency statistics.

#### Importing the metrics.http_middleware submodule

```
-- importing submodule
http_middleware = metrics.http_middleware
```

#### `http_middleware.configure_default_collector(type_name, name, help)`
  Registers a collector for the middleware and sets it as default.

  Parameters:
  * `type_name` Collector type (string): "histogram" or "average". Default is "histogram".
  * `name` Collector name (string). Default is "http_server_request_latency".
  * `help` (optional) Help description (string). Default is "HTTP Server Request Latency".

  If a collector with the same type and name already exists in the registry,
  throws an error.

#### `http_middleware.build_default_collector(type_name, name, help)`
  Registers a collector for the middleware and returns it.

  Parameters:
  * `type_name` a collector type (string): "histogram" or "average". Default is "histogram".
  * `name` a collector name (string). Default is "http_server_request_latency".
  * `help` (optional) help description (string). Default is "HTTP Server Request Latency".

  If a collector with the same type and name already exists in the registry,
  throws an error.

#### `http_middleware.set_default_collector(collector)`
  Sets the default collector.

  Parameters:
  * `collector` a middleware collector object.

#### `http_middleware.get_default_collector()`
  Returns the default collector.
  If the default collector hasn't been set yet, registers it
  (with default `http_middleware.build_default_collector(...)` parameters)
  and sets it as default.

#### `http_middleware.v1(handler, collector)`
  Latency measuring wrap-up for HTTP ver. 1.x.x handler. Returns a wrapped handler.

  Parameters:
  * `handler` a handler function.
  * `collector` a middleware collector object.
    If not set, uses the default collector
    (like in `http_middleware.get_default_collector()`).

  Usage:
  ```
  httpd:route(route, http_middleware.v1(request_handler, collector))
  ```

  For a more detailed example, see [example/HTTP/latency_v1.lua](./example/HTTP/latency_v1.lua).

#### `http_middleware.v2(collector)`
  Returns latency measuring middleware for HTTP ver. 2.x.x.

  Parameters:
  * `collector` a middleware collector object.
    If not set, uses default collector (like in `http_middleware.get_default_collector()`).

  Usage:
  ```
  router = require('http.router').new()

  router:route(route, request_handler)
  router:use(http_middleware.v2(collector), {name = 'http_instrumentation'}) -- Second argument is optional, see HTTP docs
  ```

  For a more detailed example, see [example/HTTP/latency_v2.lua](./example/HTTP/latency_v2.lua).

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

## Contribution

Feel free to send Pull Requests.
For example, you can support new time series aggregation / manipulation functions
(but be sure to check if there are any Prometheus analogues to borrow API from).

## Credits

We would like to thank Prometheus for a great API that we brusquely borrowed.
