.. _metrics-api-reference:

===============================================================================
API reference
===============================================================================

.. _collectors:

-------------------------------------------------------------------------------
Collectors
-------------------------------------------------------------------------------

An application using the ``metrics`` module has 4 primitives (called "collectors")
at its disposal:

*  :ref:`Counter <counter>`
*  :ref:`Gauge <gauge>`
*  :ref:`Histogram <histogram>`
*  :ref:`Summary <summary>`

A collector represents one or more observations that are changing over time.

..  module:: metrics

.. _counter:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Counter
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

..  function:: counter(name [, help])

    Registers a new counter.

    :param string name: Collector name. Must be unique.
    :param string help: Help description.
    :return: Counter object
    :rtype: counter_obj

.. class:: counter_obj

    .. method:: inc(num, label_pairs)

        Increments an observation under ``label_pairs``.
        If ``label_pairs`` didn't exist before, this creates it.

        :param number        num: Increase value.
        :param table label_pairs: Table containing label names as keys,
                                  label values as values.

    .. _counter-collect:

    .. method:: collect()

        :return: Array of ``observation`` objects for the given counter.

        ..  code-block:: lua

            {
                label_pairs: table,          -- `label_pairs` key-value table
                timestamp: ctype<uint64_t>,  -- current system time (in microseconds)
                value: number,               -- current value
                metric_name: string,         -- collector
            }

        :rtype: table

    .. method:: remove(label_pairs)

        Removes an observation with ``label_pairs``.

    .. method:: reset(label_pairs)

        Set an observation under ``label_pairs`` to 0.

        :param table label_pairs: Table containing label names as keys,
                                  label values as values.

.. _gauge:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Gauge
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

..  function:: gauge(name [, help])

    Registers a new gauge. Returns a Gauge object.

    :param string name: Collector name. Must be unique.
    :param string help: Help description.

    :return: Gauge object

    :rtype: gauge_obj

..  class:: gauge_obj

    ..  method:: inc(num, label_pairs)

        Same as Counter ``inc()``.

    ..  method:: dec(num, label_pairs)

        Same as ``inc()``, but decreases the observation.

    ..  method:: set(num, label_pairs)

        Same as ``inc()``, but sets the observation.

    ..  method:: collect()

        Returns an array of ``observation`` objects for the given gauge.
        For ``observation`` description, see
        :ref:`counter_obj:collect() <counter-collect>`.

    ..  method:: remove(label_pairs)

        Same as Counter ``remove()``.

.. _histogram:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Histogram
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

..  function:: histogram(name [, help, buckets])

    Registers a new histogram.

    :param string   name: Collector name. Must be unique.
    :param string   help: Help description.
    :param table buckets: Histogram buckets (an array of sorted positive numbers).
                          Infinity bucket (``INF``) is appended automatically.
                          Default is ``{.005, .01, .025, .05, .075, .1, .25, .5, .75, 1.0, 2.5, 5.0, 7.5, 10.0, INF}``.

    :return: Histogram object

    :rtype: histogram_obj

    .. NOTE::

        The histogram is just a set of collectors:

        *  ``name .. "_sum"`` - A counter holding the sum of added observations.
           Contains only an empty label set.
        *  ``name .. "_count"`` - A counter holding the number of added observations.
           Contains only an empty label set.
        *  ``name .. "_bucket"`` - A counter holding all bucket sizes under the label
           ``le`` (low or equal). So to access a specific bucket ``x`` (``x`` is a number),
           you should specify the value ``x`` for the label ``le``.

..  class:: histogram_obj

    ..  method:: observe(num, label_pairs)

        Records a new value in a histogram.
        This increments all buckets sizes under labels ``le`` >= ``num``
        and labels matching ``label_pairs``.

        :param number        num: Value to put in the histogram.
        :param table label_pairs: Table containing label names as keys,
                                  label values as values (table).
                                  A new value is observed by all internal counters
                                  with these labels specified.

    .. method:: collect()

        Returns a concatenation of ``counter_obj:collect()`` across all internal
        counters of ``histogram_obj``. For ``observation`` description,
        see :ref:`counter_obj:collect() <counter-collect>`.

    ..  method:: remove(label_pairs)

        Same as Counter ``remove()``.


.. _summary:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Summary
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

..  function:: summary(name [, help, objectives])

    Registers a new summary. Quantile computation is based on the algorithm
    `"Effective computation of biased quantiles over data streams" <https://ieeexplore.ieee.org/document/1410103>`_

    :param string   name: Collector name. Must be unique.
    :param string   help: Help description.
    :param table objectives: A list of 'targeted' φ-quantiles in the form ``{quantile = error, ... }``.
        For example: ``{[0.5]=0.01, [0.9]=0.01, [0.99]=0.01}``.
        A targeted φ-quantile is specified in the form of a φ-quantile and tolerated
        error. For example a ``{[0.5] = 0.1}`` means that the median (= 50th
        percentile) should be returned with 10 percent error. Note that
        percentiles and quantiles are the same concept, except percentiles are
        expressed as percentages. The φ-quantile must be in the interval [0, 1].
        Note that a lower tolerated error for a φ-quantile results in higher
        usage of resources (memory and CPU) to calculate the summary.

    :param table params: Table of summary parameters, used for configuring sliding
        window of time. 'Sliding window' consists of several buckets to store observations.
        New observations are added to each bucket. After a time period, the 'head' bucket
        (bucket from which observations are collected) is reset and the next bucket becomes a
        new 'head'. I.e. each bucket will store observations for
        ``max_age_time * age_buckets_count`` seconds before it will be reset.
        ``max_age_time`` sets the duration of each bucket lifetime, i.e., how long
        observations are kept before they are discarded, in seconds
        ``age_buckets_count`` sets the number of buckets of the time window. It
        determines the number of buckets used to exclude observations that are
        older than ``max_age_time`` from the Summary. The value is
        a trade-off between resources (memory and CPU for maintaining the bucket)
        and how smooth the time window is moved.
        Default value is `{max_age_time = math.huge, age_buckets_count = 1}`

    :return: Summary object

    :rtype: summary_obj

    .. NOTE::

        The summary is just a set of collectors:

        *  ``name .. "_sum"`` - A counter holding the sum of added observations.
        *  ``name .. "_count"`` - A counter holding the number of added observations.
        *  ``name`` - It's holding all quantiles under observation under the label
           ``quantile`` (low or equal). So to access a specific quantile ``x`` (``x`` is a number),
           you should specify the value ``x`` for the label ``quantile``.

..  class:: summary_obj

    ..  method:: observe(num, label_pairs)

        Records a new value in a summary.

        :param number        num: Value to put in the data stream.
        :param table label_pairs: A table containing label names as keys,
                                  label values as values (table).
                                  A new value is observed by all internal counters
                                  with these labels specified.
                                  Label ``"quantile"`` are not allowed in ``summary``.
                                  It will be added automatically.
                                  If ``max_age_time`` and ``age_buckets_count`` are set,
                                  the observed value will be added to each bucket.

    ..  method:: collect()

        Returns a concatenation of ``counter_obj:collect()`` across all internal
        counters of ``summary_obj``. For ``observation`` description,
        see :ref:`counter_obj:collect() <counter-collect>`.
        If ``max_age_time`` and ``age_buckets_count`` are set, quantile observations
        will be collect only from the head bucket in sliding window and not from every
        bucket.

    ..  method:: remove(label_pairs)

        Same as Counter ``remove()``.

.. _labels:

-------------------------------------------------------------------------------
Labels
-------------------------------------------------------------------------------

All collectors support providing ``label_pairs`` on data modification.
Labels are basically a metainfo that you associate with a metric in the format
of key-value pairs. See tags in Graphite and labels in Prometheus.
Labels are used to differentiate the characteristics of a thing being
measured. For example, in a metric associated with the total number of http
requests, you can use methods and statuses label pairs:

..  code-block:: lua

    http_requests_total_counter:inc(1, {method = 'POST', status = '200'})

You don't have to predefine labels in advance.

Using labels on your metrics allows you to later derive new time series
(visualize their graphs) by specifying conditions on label values.
In the example above, we could derive these time series:

#. The total number of requests over time with method = "POST" (and any status).
#. The total number of requests over time with status = 500 (and any method).

You can also set global labels by calling
``metrics.set_global_labels({ label = value, ...})``.

.. _metrics-functions:

-------------------------------------------------------------------------------
Metrics functions
-------------------------------------------------------------------------------

..  function:: enable_default_metrics([include, exclude])

    Enables Tarantool metrics collections.

    :param table include: Table containing names of default metrics which you need to enable.

    :param table exclude: Table containing names of default metrics which you need to exclude.

    Default metrics names:

    * "network"
    * "operations"
    * "system"
    * "replicas"
    * "info"
    * "slab"
    * "runtime"
    * "memory"
    * "spaces"
    * "fibers"
    * "cpu"
    * "vinyl"
    * "luajit"
    * "cartridge_issues"
    * "clock"

    See :ref:`metrics reference <metrics-reference>` for details.

..  function:: metrics.set_global_labels(label_pairs)

    Set global labels that will be added to every observation.

    :param table label_pairs: Table containing label names as string keys,
                              label values as values (table).

    Global labels are applied only on metrics collection and have no effect
    on how observations are stored.

    Global labels can be changed on the fly.

    Observation ``label_pairs`` has priority over global labels:
    if you pass ``label_pairs`` to an observation method with the same key as
    some global label, the method argument value will be used.

..  function:: register_callback(callback)

    Registers a function ``callback`` which will be called right before metrics
    collection on plugin export.

    :param function callback: Function which takes no parameters.

    Most common usage is for gauge metrics updates.

..  function:: unregister_callback(callback)

    Unregisters a function ``callback`` which will be called right before metrics
    collection on plugin export.

    :param function callback: Function which takes no parameters.

    Most common usage is for unregister enabled callbacks.

.. _collecting-http-statistics:

-------------------------------------------------------------------------------
Collecting HTTP requests latency statistics
-------------------------------------------------------------------------------

``metrics`` also provides a middleware for monitoring HTTP
(set by the `http <https://github.com/tarantool/http>`_ module)
latency statistics.

..  module:: metrics.http_middleware

..  function:: configure_default_collector(type_name, name, help)

    Registers a collector for the middleware and sets it as default.

    :param string type_name: Collector type: "histogram" or "summary". Default is "histogram".
    :param string      name: Collector name. Default is "http_server_request_latency".
    :param string      help: Help description. Default is "HTTP Server Request Latency".

    If a collector with the same type and name already exists in the registry,
    throws an error.

..  function:: build_default_collector(type_name, name [, help])

    Registers a collector for the middleware and returns it.

    :param string type_name: Collector type: "histogram" or "summary". Default is "histogram".
    :param string      name: Collector name. Default is "http_server_request_latency".
    :param string      help: Help description. Default is "HTTP Server Request Latency".

    If a collector with the same type and name already exists in the registry,
    throws an error.

..  function:: set_default_collector(collector)

    Sets the default collector.

    :param collector: Middleware collector object.

..  function:: get_default_collector()

    Returns the default collector.
    If the default collector hasn't been set yet, registers it (with default
    ``http_middleware.build_default_collector(...)`` parameters) and sets it
    as default.

..  function:: v1(handler, collector)

    Latency measure wrap-up for HTTP ver. 1.x.x handler. Returns a wrapped handler.

    :param function handler: Handler function.
    :param collector: Middleware collector object.
                      If not set, uses the default collector
                      (like in ``http_middleware.get_default_collector()``).

    **Usage:** ``httpd:route(route, http_middleware.v1(request_handler, collector))``

    For a more detailed example,
    see https://github.com/tarantool/metrics/blob/master/example/HTTP/latency_v1.lua

..  function:: v2(collector)

    Returns the latency measure middleware for HTTP ver. 2.x.x.

    :param collector: Middleware collector object.
                      If not set, uses the default collector
                      (like in ``http_middleware.get_default_collector()``).

    **Usage:**

    ..  code-block:: lua

        router = require('http.router').new()
        router:route(route, request_handler)
        router:use(http_middleware.v2(collector), {name = 'http_instrumentation'}) -- the second argument is optional, see HTTP docs

    For a more detailed example,
    see https://github.com/tarantool/metrics/blob/master/example/HTTP/latency_v2.lua

.. _cpu-usage-metrics:

-------------------------------------------------------------------------------
CPU usage metrics
-------------------------------------------------------------------------------

CPU metrics work only on Linux. See :ref:`metrics reference <metrics-psutils>`
for details. To enable it you should register callback:

..  code-block:: lua

    local metrics = require('metrics')

    metrics.register_callback(function()
        local cpu_metrics = require('metrics.psutils.cpu')
        cpu_metrics.update()
    end)

**Collected metrics example**

..  code-block:: none

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

..  code-block:: text

    sum by (thread_name) (idelta(tnt_cpu_thread[$__interval]))
      / scalar(idelta(tnt_cpu_total[$__interval]) / tnt_cpu_count)

.. _example:

-------------------------------------------------------------------------------
Examples
-------------------------------------------------------------------------------

Below are examples of using metrics primitives.

Notice that this usage is independent of export-plugins such as
Prometheus / Graphite / etc. For documentation on plugins usage, see
their the :ref:`Metrics plugins <metrics-plugins>` section.

Using counters:

..  code-block:: lua

    local metrics = require('metrics')

    -- create a counter
    local http_requests_total_counter = metrics.counter('http_requests_total')

    -- somewhere in the HTTP requests middleware:
    http_requests_total_counter:inc(1, {method = 'GET'})

Using gauges:

..  code-block:: lua

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

..  code-block:: lua

    local metrics = require('metrics')

    -- create a histogram
    local http_requests_latency_hist = metrics.histogram(
        'http_requests_latency', 'HTTP requests total', {2, 4, 6})

    -- somewhere in the HTTP requests middleware:
    local latency = math.random(1, 10)
    http_requests_latency_hist:observe(latency)

Using summaries:

..  code-block:: lua

    local metrics = require('metrics')

    -- create a summary with a window of 5 age buckets and 60s bucket lifetime
    local http_requests_latency = metrics.summary(
        'http_requests_latency', 'HTTP requests total',
        {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01},
        {max_age_time = 60, age_buckets_count = 5}
    )

    -- somewhere in the HTTP requests middleware:
    local latency = math.random(1, 10)
    http_requests_latency:observe(latency)
