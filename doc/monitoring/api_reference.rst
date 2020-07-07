.. _metrics-api-reference:

===============================================================================
API reference
===============================================================================

.. _collectors:

-------------------------------------------------------------------------------
Collectors
-------------------------------------------------------------------------------

An application using ``metrics`` module has 3 primitives (called collectors) at its disposal:

-  Counter
-  Gauge
-  Histogram

Collectors represent an observation or a few that are changing over time.

.. _counter:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Counter
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. module:: metrics

.. function:: counter(name [, help])``

    Registers a new counter.

    :param string name: Collector name. Must be unique.
    :param string help: Help description.
    :return: Counter object
    :rtype: counter_obj

.. class:: counter_obj
    .. method:: inc(num, label_pairs)

        Increments observation under ``label_pairs``. If ``label_pairs`` didn't exist before - this creates it.

        :param number num: Increase value.
        :param table label_pairs: Table containing label names as keys, label values as values.

    .. method:: collect()

        :return: Array of ``observation`` objects for given counter.

        .. code-block:: lua

            {
                label_pairs: table,          -- `label_pairs` key-value table
                timestamp: ctype<uint64_t>,  -- current system time (in microseconds)
                value: number,               -- current value
                metric_name: string,         -- collector
            }
        :rtype: table

.. _gauge:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Gauge
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. module:: metrics

.. function:: gauge(name [, help])``

    Registers a new gauge. Returns Counter object.

    :param string name: Collector name. Must be unique.
    :param string help: Help description.
    :return: Gauge object
    :rtype: gauge_obj

.. class:: gauge_obj
    .. method:: inc(num, label_pairs)
        Same as Counter ``inc()``.

    .. method:: inc(num, label_pairs)
        Same as ``inc()``, but decreases the observation.

    .. method:: set(num, label_pairs)
        Same as ``inc()``, but sets the observation.

    .. method:: collect()
        Returns array of ``observation`` objects for given gauge. For ``observation`` description see ``counter_obj:collect()`` section.

.. _histogram:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Histogram
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. module:: metrics

.. function:: histogram(name [, help, buckets])

    Registers a new histogram.

    :param string name: Collector name. Must be unique.
    :param string help: Help description.
    :param table buckets:
        Histogram buckets (an array of sorted positive numbers). Infinity bucket (``INF``) is appended automatically. Default is {.005, .01, .025, .05, .075, .1, .25, .5, .75, 1.0, 2.5, 5.0, 7.5, 10.0, INF}.
    :return: Histogram object.
    :rtype: histogram_obj

    **NOTE**: The histogram is just a set of collectors:

    -  ``name .. "_sum"`` - Counter holding sum of added observations. Has only empty labelset.
    -  ``name .. "_count"`` - Counter holding number of added observations. Has only empty labelset.
    -  ``name .. "_bucket"`` - Counter holding all bucket sizes under label ``le`` (low or equal). So to access specific bucket ``x`` (``x`` is a number), you should specify value ``x`` for label ``le``.

.. class:: histogram_obj

    .. method: observe(num, label_pairs)

        Records a new value in histogram. This increments all buckets sizes under labels ``le`` >= ``num`` and labels matching ``label_pairs``.
        :param number num: Value to put in histogram.
        :param table label_pairs: Table containing label names as keys, label values as values (table). New value is observed by all internal counters with these labels specified.

    .. method: collect()
        Returns concatenation of ``counter_obj:collect()`` across all internal counters of ``histogram_obj``. For ``observation`` description see ``counter_obj:collect()`` section.

.. _average:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Average
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Can be used only as HTTP statistics collector (described below) and cannot be built explicitly.

.. class:: histogram_obj

    .. method: collect()

        :return:
            A list of two observations:
            -  ``name .. "_avg"`` - average value of observations for the observing
            period (time from previous collect call to now),
            -  ``name .. "_count"`` - observation count for the same period.
                For ``observation`` description see ``counter_obj:collect()``
            section.

.. _labels:

-------------------------------------------------------------------------------
Labels
-------------------------------------------------------------------------------

All collectors support providing ``label_pairs`` on data modification. Labels are basically a metainfo that you associate with a metric in format
of key-value pairs. See tags in Graphite and labels in Prometheus.
Labels are used to differentiate the characteristics of a thing being
measured. For example, in a metric associated with http total number of requests you can use methods and statuses label pairs:

.. code-block:: lua

    http_requests_total_counter:inc(1, {method = 'POST', status = '200'})

You don't have to predefine labels in advance.

Using labels on your metrics allows you to later derive new time series (visualize their graphs) by specifying conditions on label values. In above example, we could
derive a time series:

#. total number of requests over time with method = "POST" (and any status).
#. total number of requests over time with status = 500 (and any method).

You can also set global labels by calling ``metrics.set_global_labels({ label = value, ...})``.

.. module:: metrics

.. function:: enable_default_metrics()
    Enables default metrics collections. Collects tarantool metrics, ported from https://github.com/tarantool/stat

.. function:: metrics.set_global_labels(label_pairs)
    Set global labels that will be added to every observation.

    :param table label_pairs: Table containing label names as string keys, label values as values (table).

    Global labels applied only on metrics collect and have no effect on observations' storage. Global labels can be changed along the way. Observation ``label_pairs`` are prior to global labels: if you pass ``label_pairs`` to observation method with the same key as some global label, the method argument value will be used.

.. function:: register_callback(callback)

    Registers a function ``callback`` which will be called right before metrics collection on plugin export.

    :param function callback: Function which takes no parameters.

    Most common usage is for gauge metrics updates.

.. _collecting-http-statistics:

-------------------------------------------------------------------------------
Collecting HTTP requests latency statistics
-------------------------------------------------------------------------------

``metrics`` also provides a middleware for monitoring HTTP (set by `http <https://github.com/tarantool/http>`__ module) latency statistics.

.. module:: metrics.http_middleware

.. function:: configure_default_collector(type_name, name, help)

    Registers collector for middleware and sets it as default.

    :param string type_name: Collector type: "histogram" or "average". Default is "histogram".
    :param string name: Collector name. Default is "http_server_request_latency".
    :param string help: Help description. Default is "HTTP Server Request Latency".

    If collector with the same type and name already exists in registry, throws an error.

.. function:: build_default_collector(type_name, name [, help])

    Registers collector for middleware and returns it.

    :param string type_name: Collector type: "histogram" or "average". Default is "histogram".
    :param string name: Collector name. Default is "http_server_request_latency".
    :param string help: Help description. Default is "HTTP Server Request Latency".

    If collector with the same type and name already exists in registry, throws an error.

.. function:: set_default_collector(collector)

    Sets default collector.

    :param collector: Middleware collector object.

.. function:: get_default_collector()

    Returns default collector. If default collector hasn't been set yet, registers it (with default ``http_middleware.build_default_collector(...)`` parameters) and sets it as default.

.. function:: v1(handler, collector)

    Latency measure wrap-up for HTTP ver. 1.x.x handler. Returns wrapped handler.

    :param function handler: Handler function.
    :param collector: Middleware collector object. If not set, uses default collector (like in ``http_middleware.get_default_collector()``).

    **Usage:** ``httpd:route(route, http_middleware.v1(request_handler, collector))``

    For more detailed example see `example/HTTP/latency\_v1.lua <./example/HTTP/latency_v1.lua>`__.

.. function:: v2(collector)

    Returns latency measure middleware for HTTP ver. 2.x.x.

    :param collector: Middleware collector object. If not set, uses default collector (like in ``http_middleware.get_default_collector()``).

    **Usage:**

    .. code-block:: lua

        router = require('http.router').new()
        router:route(route, request_handler)
        router:use(http_middleware.v2(collector), {name = 'http_instrumentation'}) -- Second argument is optional, see HTTP docs

    For more detailed example see `example/HTTP/latency\_v2.lua <./example/HTTP/latency_v2.lua>`__.

.. _cpu-usage-metrics:

-------------------------------------------------------------------------------
CPU usage metrics
-------------------------------------------------------------------------------

**Collected metrics example**

.. code-block::

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

**Prometheus query aggregated by thread name**

.. code-block:: promql

    sum by (thread_name) (idelta(tnt_cpu_thread[$__interval]))
      / scalar(idelta(tnt_cpu_total[$__interval]) / tnt_cpu_count)

.. _example:

-------------------------------------------------------------------------------
Examples
-------------------------------------------------------------------------------

Below are examples of using metrics primitives.

Note that this usage is independent of export-plugins such as Prometheus / Graphite / etc. For documentation on plugins usage, see Plugins.

Using counters:

.. code-block:: lua

    local metrics = require('metrics')

    -- create a counter
    local http_requests_total_counter = metrics.counter('http_requests_total')

    -- somewhere in HTTP requests middleware:
    http_requests_total_counter:inc(1, {method = 'GET'})

Using gauges:

.. code-block:: lua

    local metrics = require('metrics')

    -- create a gauge
    local cpu_usage_gauge = metrics.gauge('cpu_usage', 'CPU usage')

    -- register a lazy gauge value update
    -- this will be called whenever the export is invoked in any plugins
    metrics.register_callback(function()
        local current_cpu_usage = math.random()
        cpu_usage_gauge:set(current_cpu_usage, {app = 'tarantool'})
    end)

Using histograms:

.. code-block:: lua

    local metrics = require('metrics')

    -- create a histogram
    local http_requests_latency_hist = metrics.histogram(
        'http_requests_latency', 'HTTP requests total', {2, 4, 6})

    -- somewhere in the HTTP requests middleware:
    local latency = math.random(1, 10)
    http_requests_latency_hist:observe(latency)
