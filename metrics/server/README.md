# Metrics Server

Metrics Server is essentially a database, storing timeseries and supporting flexible quering.  

The Server must expose `metric_server.execute(query_snippet)` global function to allow outside parties to access metrics stored in it.

Metrics client can push single observations to the Server   

### Client-Server Communication

Client uses net.box builtin module to communicate observations to the Server.  
It creates a fiber that is periodically collects data from the collectors and pushes it to the Server.  
The push is handled via `metric_server.add_observation(obs)` globally exposed function on the Server side.  

## Client API

#### `metrics.connect(options)`
  Creates new connection which uploads collectors to remote Metrics Server.    
  Internally, uses `client_obj.collect()` to collect the data.  
  * `option` Table containing configuration.
    - `host` Server host (string). Default is 'localhost'.
    - `port` Server port (number). Default is 3301.
    - `upload_timeout` Timeout (number) with which collectors observations are uploaded to the Server in seconds. Default is 1 (second).

## Server API

```lua
-- import server module
metrics_server = require('metrics.server')
```

#### `metrics_server.start(options)`
  Starts the Server and observations retention fiber.
  Server is collecting metrics from clietns, deleting observations from timeseries per retention policy.
  Returns Server object.
  * `option` Table containing configuration.
    - `retention_tuples` Number of tuples for retention. Default is `10 * 1000 * 1000`.

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
  Returns vector object holding timeseries for every label set that is a superset of `label_pairs` in a collector with `metric_name`.  
  If `past` is `nil`, than instant vector is returned.  
  Otherwise range vector is returned.

  * `metric_name` Name of collector (string).
  * `label_pairs` Table containing label names as keys, label values as values (table). This is a filtering table. The available label sets are matched against it.
  * `past` Number of past milliseconds (number) for which to store observations in timeseries since moment of invoking.

#### `vector_obj.(__add | __unm | __sub | __pow | __mul | __div)(self, num)`
  Returns an original vector in which to every observation in every timeseries the specified operation has been applied.
  * `self` Left hand side - vector.
  * `num` Right hand side - number.

#### `metrics_server.avg_over_time(vec)`
  Averages vector per timeseries.  
  Returns averaged vector.
  * `vec` Vector.

#### `metrics_server.rate(vec)`
  Returns a vector in which for every timeseries of `vec` there will be a timeseries with single value - average increase rate of timeseries.  
  This accounts for counter resets.
  * `vec` Vector created from Counter collector.

#### `metrics_server.increase(vec)`
  Returns a vector in which for every timeseries of `vec` there will be a timeseries with single value - increase of timeseries.  
  This accounts for counter resets.
  * `vec` Vector created from Counter collector.

#### `metrics_server.resets(vec)`
  Returns a vector in which for every timeseries of `vec` there will be a timeseries with single value - number of counter resets.
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
