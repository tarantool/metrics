# Metrics

Metrics is a tool to collect, store and manipulate metrics timeseriess.  
Metrics uses a collection of primitives borrowed from Prometheus TSDB, which can be exported to any TSDB or can be used to build complex metrics with server-side aggregation and filtering.


## Installation

```bash
cd ${PROJECT_ROOT}
tarantoolctl rocks install metrics
```

## Export Plugins
In order to easily export metrics to any TSDB you can use one of supported export plugins:

- [Graphite](./metrics/plugins/graphite/README.md)

or you can write your [custom plugin](./metrics/plugins/README.md) and use it. 
Hopefully, plugins for other TSDBs will be supported soon.

## API

### Collectors

The application using `metrics` module has 3 primitives (called collectors) at its disposal:
- Counter
- Gauge
- Histogram

Collectors represent an observation or a few that are changing over time.

Counter and Gauge collectors support `labels`, which are essentially a key-value pairs.  
Labels allow collectors to store a separate observation per each label set added.  
New label sets are added automatically when collector invokes modification function with this label set specified for the first time.

------------------------------------------------------------------------


```lua
-- importing metrics
metrics = require('metrics')
```

#### `metrics.collect()`

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

#### `client_obj.register_callback(callback)`
  Registers a function `callback` which will be called before collecting observations every time when `metrics.collect()` called.
  * `callback` Function which takes no parameters.

  It may be used for calculation some metric right before collecting.


### Creating and Using Collectors

#### Counter

#### `metrics.counter(name, help)`
  Registers a new counter.
  Returns Counter object.
  * `name` Collector name (string). Must be unique.
  * `help` Help description (string). Currently it's just ignored.

#### `counter_obj:inc(num, label_pairs)`
  Increments observation under `label_pairs`. If `label_pairs` didn't exist before - this creates it.
  * `num` Increase value (number).
  * `label_pairs` Table containing label names as keys, label values as values (table).

#### `counter_obj:collect()`
  Returns array of `observation` objects for given counter.  
  For `observation` description see `metrics.collect()` section.

#### Gauge

#### `metrics.gauge(name, help)`
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
  Returns array of `observation` objects for given gauge.  
  For `observation` description see `metrics.collect()` section.

#### Histogram

#### `client_obj.histogram(name, help, buckets)`
  Registers a new histogram.
  Returns Histogram object.
  * `name` Collector name (string). Must be unique.
  * `help` Help description (string). Currently it's just ignored.
  * `buckets` Histogram buckets (array of positive sorted numbers). `INF` bucket is added automatically. Default is 
{.005, .01, .025, .05, .075, .1, .25, .5, .75, 1.0, 2.5, 5.0, 7.5, 10.0, INF}.

  **NOTE**: The histogram is just a set of collectors:
  * `name .. "_sum"` - Counter holding sum of added observations. Has only empty labelset.
  * `name .. "_count"` - Counter holding number of added observations. Has only empty labelset.
  * `name .. "_bucket"` - Counter holding all bucket sizes under label `le` (low or equal). So to access specific bucket `x` (`x` is a number), you should specify value `x` for label `le`.

#### `histogram_obj:observe(num, label_pairs)`
  Records a new value in histogram. This increments all buckets sizes under labels `le` >= `num` and labels matching `label_pairs`.
  * `num` Value to put in histogram (number).
  * `label_pairs` Table containing label names as keys, label values as values (table). New value is observed by all internal counters with these labels specified 

#### `histogram_obj:collect()`
  Returns concatenation of `counter_obj:collect()` across all internal counters
  of `histogram_obj`.  
  See above `counter_obj:collect()` for details.

## CONTRIBUTION

Feel free to send Pull Requests. E.g. you can support new timeseriess aggregation / manipulation functions (but be sure to check if there are any Prometheus analogues to borrow API from).

## CREDIT

We would like to thank Prometheus for a great API that we brusquely borrowed.
