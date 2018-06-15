# Metrics

Metrics is a tool to collect, store and manipulate metrics timeseriess.  
Metrics uses a collection of primitives borrowed from Prometheus TSDB, which can be used to build complex metrics with Server-side aggregation and filtering.

## Architecture

### Overview

Metrics uses a client-server architecture.  
`require('metrics.server')` is a Lua-module which is essentially a database, storing timeseriess and supporting flexible quering.  
`require('metrics')` is a Lua-module which is responsible for pushing single observations to the Server   

The application using Client module has 3 primitives (called collectors) at its disposal:
- Counter
- Gauge
- Histogram

They are called Collectors.

### Collectors
Collectors represent an observation or a few that are changing over time.

Counter and Gauge collectors support `labels`, which are essentially a key-value pairs.  
Labels allow collectors to store a separate observation per each label set added.  
New label sets are added automatically when collector invokes modification function with this label set specified for the first time.


The Server must expose `metric_server.execute(query_snippet)` global function to allow outside parties to access metrics stored in it.

### Client-Server Communication
Client uses net.box builtin module to communicate observations to the Server.  
It creates a fiber that is periodically collects data from the collectors and pushes it to the Server.  
The push is handled via `metric_server.add_observation(obs)` globally exposed function on the Server side.  

------------------------------------------------------------------------

## Installation

```bash
cd ${PROJECT_ROOT}
tarantoolctl rocks install metrics
```

## API

### Client API

```lua
-- import client module
metrics_client = require('metrics')
```

#### `metrics_client.connect(options)`
  Creates new connection which uploads collectors to remote metrics server.  
  Returns Client object.  
  Internally, uses `client_obj.registry:collect()` to collect the data.  
  * `option` Table containing configuration.
    - `host` Server host (string). Default is 'localhost'.
    - `port` Server port (number). Default is 3301.
    - `upload_timeout` Timeout (number) with which collectors observations are uploaded to the Server in seconds. Default is 1 (second).

#### `client_obj.counter(name, help)`
  Registers a new counter.
  Returns Counter object.
  * `name` Collector name (string). Must be unique.
  * `help` Help description (string). Currently it's just ignored.

#### `counter_obj:inc(num, label_pairs)`
  Increments observation under `label_pairs`. If `label_pairs` didn't exist before - this creates it.
  * `num` Increase value (number).
  * `label_pairs` Table containing label names as keys, label values as values (table).

#### `counter_obj:collect()`
  Returns array of `data`s.
  `data` is a Lua table:
  ```lua
  {
    label_pairs: table,          -- `label_pairs` key-value table
    timestamp: ctype<uint64_t>,  -- current system time (in microseconds)
    value: number,               -- current value
    metric_name: string,         -- name of `counter_obj`
  }
  ```

#### `client_obj.gauge(name, help)`
  Registers a new gauge.
  Returns Gauge object.
  * `name` Collector name (string). Must be unique.
  * `help` Help description (string). Currently it's just ignored.

#### `gauge_obj:inc(num, label_pairs)`
  Same as Counter `inc()`.

#### `gauge_obj:dec(num, label_pairs)`
  Same as `inc()`, but decreases the observation.

#### `gauge_obj:set(num, label_pairs)`
  Same as `inc()`, but sets the observation.

#### `gauge_obj:collect()`
  (same as `counter_obj:collect()`)
  Returns array of `data`s.
  `data` is a Lua table:
  ```lua
  {
    label_pairs: table,          -- `label_pairs` key-value table
    timestamp: ctype<uint64_t>,  -- current system time (in microseconds)
    value: number,               -- current value
    metric_name: string,         -- name of `counter_obj`
  }
  ```

#### `client_obj.histogram(name, help, buckets)`
  Registers a new histogram.
  Returns Histogram object.
  * `name` Collector name (string). Must be unique.
  * `help` Help description (string). Currently it's just ignored.
  * `buckets` Histogram buckets (array of positive sorted numbers). `INF` bucket is added automatically. Default is 
{.005, .01, .025, .05, .075, .1, .25, .5, .75, 1.0, 2.5, 5.0, 7.5, 10.0, INF}.

  NOTE:
  No collectors will be created with name `name`.
  The histogram is just a collection of collectors:
  * `name .. "_sum"` -- Counter holding sum of added observations. Has only empty labelset.
  * `name .. "_count"` -- Counter holding number of added observations. Has only empty labelset.
  * `name .. "_bucket"` -- Counter holding all bucket sizes under label `le`. So to access specific bucket x (x is a number), you should specify value x for label `le`.

#### `histogram_obj:observe(num)`
  Records a new value in histogram. This puts `num` to the last bucket that is >= `num`.
  * `num` Value to put in histogram (number).

#### `histogram_obj:collect()`
  Returns concatenation of `counter_obj:collect()` across all internal counters
  of `histogram_obj`. See above `counter_obj:collect()` for details.

#### `client_obj.registry`
  Global registry.  
  All collectors created via `client_obj.(counter()|gauge()|histogram())` are
  automatically registered in it.

#### `client_obj.registry:collect()`
  Returns concatenation of `obj:collect()` across all collectors created.

#### `client_obj.registry:register_callback(callback)`
  Registers a callback `callback` which will be called before  
  `client_obj.registry:collect()`.
  * `callback` Function which takes no parameters.

### Server API

```lua
-- import server module
metrics_server = require('metrics.server')
```

#### `metrics_server`
  Metrics Server. Returns Metrics Server object having following fields:
  * `start(options)` Starts the Server and observations retention fiber.
  * `execute(query_snippet)` Evaluates `query` in a special sandbox allowing for some syntax sugar. Returns the result.
  * `add_observation(obs)` A gateway function to Metrics Client. You must make it global for client to be able to upload observation to the Server.

#### `metrics_server.start(options)`
  Starts the Server and observations retention fiber.
  Server is colectring metrics from clietns, deleting observations from timeseriess per retention policy.
  Returns Server object.
  * `option` Table containing configuration.
    - `retention_tuples` Server host (string). Default is 'localhost'.

#### `metrics_server.execute(query_snippet)`
  Evaluates `query` in a special sandbox allowing for some syntax sugar.  
  Returns the result.  
  Intended to be used via `net.box`.
  * `query_snippet` String with Lua code. Here you can use `collector_name(...)` instead of `vector('collector_name', ...)`.

#### (Used by Metrics Client transparently, MAKE IT GLOBAL) `metrics_server.add_observation(obs)`
  A gateway function to Metrics Client.  
  YOU MUST MAKE IT GLOBAL for Metrics Client to be able to upload observation to the Server.
  * `metric_name` Name of collector (string).
  * `label_pairs` Table containing label names as keys, label values as values (table).
  * `value` Observation value (number).
  * `timestamp` fiber.time64() output from Client side (cdata).

#### `metrics_server.histogram_quantile(phi, vec)`
  Approximates percentile given histogram.  
  Returns the quantile.
  * `phi` Percentage (number between 0 and 1) for quantile (e.g. 0.99 would calculate 99th percentile)
  * `vec` Histogram's `_bucket` collector vector.

#### `metrics_server.vector(metric_name, label_pairs, past)`
  Returns vector object holding timeseriess for every label set that is a superset of `label_pairs` in a collector with `metric_name`.  
  If `past` is `nil`, than instant vector is returned.  
  Otherwise range vector is returned.
  
  * `metric_name` Name of collector (string).
  * `label_pairs` Table containing label names as keys, label values as values (table). This is a filtering table. The available label sets are matched against it.
  * `past` Number of past milliseconds (number) for which to store observations in timeseriess since moment of invoking.

#### `vector_obj.(__add | __unm | __sub | __pow | __mul | __div)(self, num)`
  Returns an original vector in which to every observation in every timeseries the specified operation has been applied.
  * `self` Left hand side -- vector.
  * `num` Right hand side -- number.

#### `metrics_server.avg_over_time(vec)`
  Averages vector per timeseries.  
  Returns averaged vector.
  * `vec` Vector.

#### `metrics_server.rate(vec)`
  Returns a vector in which for every timeseries of `vec` there will be a timeseries with single value -- average increase rate of timeseries.  
  This accounts for counter resets.
  * `vec` Vector created from Counter collector.

#### `metrics_server.increase(vec)`
  Returns a vector in which for every timeseries of `vec` there will be a timeseries with single value -- increase of timeseries.  
  This accounts for counter resets.
  * `vec` Vector created from Counter collector.

#### `metrics_server.resets(vec)`
  Returns a vector in which for every timeseries of `vec` there will be a timeseries with single value -- number of counter resets.
  * `vec` Vector created from Counter collector.

#### `metrics_server.(secs | seconds)(num)`
  Returns number of milliseconds in `num` seconds.

#### `metrics_server.(mins | minutes)(num)`
  Returns number of milliseconds in `num` minutes.

#### `metrics_server.hours(num)`
  Returns number of milliseconds in `num` hours.

#### `metrics_server.days(num)`
  Returns number of milliseconds in `num` days.

#### `metrics_server.weeks(num)`
  Returns number of milliseconds in `num` weeks.

## CONTRIBUTION

Feel free to send Pull Requests. E.g. you can support new timeseriess aggregation / manipulation functions (but be sure to check if there are any Prometheus analogues to borrow API from).

## CREDIT

We would like to thank Prometheus for a great API that we brusquely borrowed.
