..  _metrics-api_reference:

API reference
=============

.. _metrics-api_reference-collectors:

Collectors
----------

An application using the ``metrics`` module has 4 primitives, called **collectors**,
at its disposal:

..  contents::
    :local:
    :depth: 1

A collector represents one or more observations that change over time.

..  module:: metrics

..  _metrics-api_reference-counter:

counter
~~~~~~~

..  function:: counter(name [, help])

    Register a new counter.

    :param string name: collector name. Must be unique.
    :param string help: collector description.
    :return: A counter object.
    :rtype: counter_obj

..  class:: counter_obj

    ..  _metrics-api_reference-counter_inc:

    ..  method:: inc(num, label_pairs)

        Increment the observation for ``label_pairs``.
        If ``label_pairs`` doesn't exist, the method creates it.

        :param number        num: increment value.
        :param table label_pairs: table containing label names as keys,
                                  label values as values. Note that both
                                  label names and values in ``label_pairs``
                                  are treated as strings.

    ..  _metrics-api_reference-counter_collect:

    ..  method:: collect()

        :return: Array of ``observation`` objects for a given counter.

        ..  code-block:: lua

            {
                label_pairs: table,          -- `label_pairs` key-value table
                timestamp: ctype<uint64_t>,  -- current system time (in microseconds)
                value: number,               -- current value
                metric_name: string,         -- collector
            }

        :rtype: table

    ..  _metrics-api_reference-counter_remove:

    ..  method:: remove(label_pairs)

        Remove the observation for ``label_pairs``.

    ..  method:: reset(label_pairs)

        Set the observation for ``label_pairs`` to 0.

        :param table label_pairs: table containing label names as keys,
                                  label values as values. Note that both
                                  label names and values in ``label_pairs``
                                  are treated as strings.

.. _metrics-api_reference-gauge:

gauge
~~~~~

..  function:: gauge(name [, help])

    Register a new gauge.

    :param string name: collector name. Must be unique.
    :param string help: collector description.

    :return: A gauge object.

    :rtype: gauge_obj

..  class:: gauge_obj

    ..  method:: inc(num, label_pairs)

        Works like the ``inc()`` function
        of a :ref:`counter <metrics-api_reference-counter_inc>`.

    ..  method:: dec(num, label_pairs)

        Works like ``inc()``, but decrements the observation.

    ..  method:: set(num, label_pairs)

        Sets the observation for ``label_pairs`` to ``num``.

    ..  method:: collect()

        Returns an array of ``observation`` objects for a given gauge.
        For the description of ``observation``, see
        :ref:`counter_obj:collect() <metrics-api_reference-counter_collect>`.

    ..  method:: remove(label_pairs)

        Works like the ``remove()`` function
        of a :ref:`counter <metrics-api_reference-counter_remove>`.

..  _metrics-api_reference-histogram:

histogram
~~~~~~~~~

..  function:: histogram(name [, help, buckets])

    Register a new histogram.

    :param string   name: collector name. Must be unique.
    :param string   help: collector description.
    :param table buckets: histogram buckets (an array of sorted positive numbers).
                          The infinity bucket (``INF``) is appended automatically.
                          Default: ``{.005, .01, .025, .05, .075, .1, .25, .5, .75, 1.0, 2.5, 5.0, 7.5, 10.0, INF}``.

    :return: A histogram object.

    :rtype: histogram_obj

    ..  note::

        A histogram is basically a set of collectors:

        *   ``name .. "_sum"`` -- a counter holding the sum of added observations.
        *   ``name .. "_count"`` -- a counter holding the number of added observations.
        *   ``name .. "_bucket"`` -- a counter holding all bucket sizes under the label
            ``le`` (less or equal). To access a specific bucket -- ``x`` (where ``x`` is a number),
            specify the value ``x`` for the label ``le``.

..  class:: histogram_obj

    ..  method:: observe(num, label_pairs)

        Record a new value in a histogram.
        This increments all bucket sizes under the labels ``le`` >= ``num``
        and the labels that match ``label_pairs``.

        :param number        num: value to put in the histogram.
        :param table label_pairs: table containing label names as keys,
                                  label values as values.
                                  All internal counters that have these labels specified
                                  observe new counter values.
                                  Note that both label names and values in ``label_pairs``
                                  are treated as strings.

    ..  method:: collect()

        Return a concatenation of ``counter_obj:collect()`` across all internal
        counters of ``histogram_obj``. For the description of ``observation``,
        see :ref:`counter_obj:collect() <metrics-api_reference-counter_collect>`.

    ..  method:: remove(label_pairs)

        Works like the ``remove()`` function
        of a :ref:`counter <metrics-api_reference-counter_remove>`.


..  _metrics-api_reference-summary:

summary
~~~~~~~

..  function:: summary(name [, help, objectives, params])

    Register a new summary. Quantile computation is based on the
    `"Effective computation of biased quantiles over data streams" <https://ieeexplore.ieee.org/document/1410103>`_
    algorithm.

    :param string   name: сollector name. Must be unique.
    :param string   help: collector description.
    :param table objectives: a list of "targeted" φ-quantiles in the ``{quantile = error, ... }`` form.
        Example: ``{[0.5]=0.01, [0.9]=0.01, [0.99]=0.01}``.
        The targeted φ-quantile is specified in the form of a φ-quantile and the tolerated
        error. For example, ``{[0.5] = 0.1}`` means that the median (= 50th
        percentile) is to be returned with a 10-percent error. Note that
        percentiles and quantiles are the same concept, except that percentiles are
        expressed as percentages. The φ-quantile must be in the interval ``[0, 1]``.
        A lower tolerated error for a φ-quantile results in higher memory and CPU
        usage during summary calculation.

    :param table params: table of the summary parameters used to configuring the sliding
        time window. This window consists of several buckets to store observations.
        New observations are added to each bucket. After a time period, the head bucket
        (from which observations are collected) is reset, and the next bucket becomes the
        new head. This way, each bucket stores observations for
        ``max_age_time * age_buckets_count`` seconds before it is reset.
        ``max_age_time`` sets the duration of each bucket's lifetime -- that is, how
        many seconds the observations are kept before they are discarded.
        ``age_buckets_count`` sets the number of buckets in the sliding time window.
        This variable determines the number of buckets used to exclude observations
        older than ``max_age_time`` from the summary. The value is
        a trade-off between resources (memory and CPU for maintaining the bucket)
        and how smooth the time window moves.
        Default value: ``{max_age_time = math.huge, age_buckets_count = 1}``.

    :return: A summary object.

    :rtype: summary_obj

    ..  note::

        A summary represents a set of collectors:

        *   ``name .. "_sum"`` -- a counter holding the sum of added observations.
        *   ``name .. "_count"`` -- a counter holding the number of added observations.
        *   ``name`` holds all the quantiles under observation that find themselves
            under the label ``quantile`` (less or equal).
            To access bucket ``x`` (where ``x`` is a number),
            specify the value ``x`` for the label ``quantile``.

..  class:: summary_obj

    ..  method:: observe(num, label_pairs)

        Record a new value in a summary.

        :param number        num: value to put in the data stream.
        :param table label_pairs: a table containing label names as keys,
                                  label values as values.
                                  All internal counters that have these labels specified
                                  observe new counter values.
                                  You can't add the ``"quantile"`` label to a summary.
                                  It is added automatically.
                                  If ``max_age_time`` and ``age_buckets_count`` are set,
                                  the observed value is added to each bucket.
                                  Note that both label names and values in ``label_pairs``
                                  are treated as strings.

    ..  method:: collect()

        Return a concatenation of ``counter_obj:collect()`` across all internal
        counters of ``summary_obj``. For the description of ``observation``,
        see :ref:`counter_obj:collect() <metrics-api_reference-counter_collect>`.
        If ``max_age_time`` and ``age_buckets_count`` are set, quantile observations
        are collected only from the head bucket in the sliding time window,
        not from every bucket. If no observations were recorded,
        the method will return ``NaN`` in the values.

    ..  method:: remove(label_pairs)

        Works like the ``remove()`` function
        of a :ref:`counter <metrics-api_reference-counter_remove>`.

..  _metrics-api_reference-labels:

Labels
------

All collectors support providing ``label_pairs`` on data modification.
A label is a piece of metainfo that you associate with a metric in the key-value format.
See tags in Graphite and labels in Prometheus.
Labels are used to differentiate between the characteristics of a thing being
measured. For example, in a metric associated with the total number of HTTP
requests, you can represent methods and statuses as label pairs:

..  code-block:: lua

    http_requests_total_counter:inc(1, {method = 'POST', status = '200'})

You don't have to predefine labels in advance.

With labels, you can extract new time series (visualize their graphs)
by specifying conditions with regard to label values.
The example above allows extracting the following time series:

#.  The total number of requests over time with ``method = "POST"`` (and any status).
#.  The total number of requests over time with ``status = 500`` (and any method).

You can also set global labels by calling
``metrics.set_global_labels({ label = value, ...})``.

..  _metrics-api_reference-functions:

Metrics functions
-----------------

..  function:: enable_default_metrics([include, exclude])

    Enable Tarantool metric collection.

    :param table include: table containing the names of the default metrics that you need to enable.

    :param table exclude: table containing the names of the default metrics that you need to exclude.

    Default metric names:

    *   ``network``
    *   ``operations``
    *   ``system``
    *   ``replicas``
    *   ``info``
    *   ``slab``
    *   ``runtime``
    *   ``memory``
    *   ``spaces``
    *   ``fibers``
    *   ``cpu``
    *   ``vinyl``
    *   ``luajit``
    *   ``cartridge_issues``
    *   ``cartridge_failover``
    *   ``clock``
    *   ``event_loop``

    See :ref:`metrics reference <metrics-reference>` for details.

..  function:: set_global_labels(label_pairs)

    Set the global labels to be added to every observation.

    :param table label_pairs: table containing label names as string keys,
                              label values as values.

    Global labels are applied only to metric collection. They have no effect
    on how observations are stored.

    Global labels can be changed on the fly.

    ``label_pairs`` from observation objects have priority over global labels.
    If you pass ``label_pairs`` to an observation method with the same key as
    some global label, the method argument value will be used.

    Note that both label names and values in ``label_pairs`` are treated as strings.

..  function:: collect()

    Collect observations from each collector.

..  class:: registry

    ..  method:: unregister(collector)

        Remove a collector from the registry.

        :param collector_obj collector: the collector to be removed.

    **Example:**

    ..  code-block:: lua

        local collector = metrics.gauge('some-gauge')

        -- after a while, we don't need it anymore

        metrics.registry:unregister(collector)

    ..  method:: find(kind, name)

        Find a collector in the registry.

        :param string kind: collector kind (``counter``, ``gauge``, ``histogram``, or ``summary``).
        :param string name: collector name.

        :return: A collector object or ``nil``.

        :rtype: collector_obj

    **Example:**

    ..  code-block:: lua

        local collector = metrics.gauge('some-gauge')

        collector = metrics.registry:find('gauge', 'some-gauge')

..  function:: register_callback(callback)

    Register a function named ``callback``, which will be called right before metric
    collection on plugin export.

    :param function callback: a function that takes no parameters.

    This method is most often used for gauge metrics updates.

    **Example:**

    ..  code-block:: lua

        metrics.register_callback(function()
            local cpu_metrics = require('metrics.psutils.cpu')
            cpu_metrics.update()
        end)

..  function:: unregister_callback(callback)

    Unregister a function named ``callback`` that is called right before metric
    collection on plugin export.

    :param function callback: a function that takes no parameters.

    **Example:**

    ..  code-block:: lua

        local cpu_callback = function()
            local cpu_metrics = require('metrics.psutils.cpu')
            cpu_metrics.update()
        end

        metrics.register_callback(cpu_callback)

        -- after a while, we don't need that callback function anymore

        metrics.unregister_callback(cpu_callback)

..  function:: invoke_callbacks()

    Invoke all registered callbacks. Has to be called before each ``collect()``.
    If you're using one of the default exporters,
    ``invoke_callbacks()`` will be called by the exporter.

..  _metrics-api_reference-role_functions:

Metrics role API
----------------

Below are the functions that you can call
with ``metrics = require('cartridge.roles.metrics')`` specified in your ``init.lua``.

..  function:: set_export(export)

    :param table export: a table containing paths and formats of the exported metrics.

    Configure the endpoints of the metrics role:

    ..  code-block:: lua

        local metrics = require('cartridge.roles.metrics')
        metrics.set_export({
            {
                path = '/path_for_json_metrics',
                format = 'json'
            },
            {
                path = '/path_for_prometheus_metrics',
                format = 'prometheus'
            },
            {
                path = '/health',
                format = 'health'
            }
        })

    You can add several entry points of the same format but with different paths,
    for example:

    ..  code-block:: lua

        metrics.set_export({
            {
                path = '/path_for_json_metrics',
                format = 'json'
            },
            {
                path = '/another_path_for_json_metrics',
                format = 'json'
            },
        })

..  function:: set_default_labels(label_pairs)

    Add default global labels. Note that both
    label names and values in ``label_pairs``
    are treated as strings.

    :param table label_pairs: Table containing label names as string keys,
                              label values as values.

    ..  code-block:: lua

        local metrics = require('cartridge.roles.metrics')
        metrics.set_default_labels({ ['my-custom-label'] = 'label-value' })

..  _metrics-api_reference-collecting_http_statistics:

Collecting HTTP request latency statistics
------------------------------------------

``metrics`` also provides middleware for monitoring HTTP
(set by the `http <https://github.com/tarantool/http>`_ module)
latency statistics.

..  module:: metrics.http_middleware

..  function:: configure_default_collector(type_name, name, help)

    Register a collector for the middleware and set it as default.

    :param string type_name: collector type: ``histogram`` or ``summary``. The default is ``histogram``.
    :param string      name: collector name. The default is ``http_server_request_latency``.
    :param string      help: collector description. The default is ``HTTP Server Request Latency``.

    **Possible errors:**

    *   A collector with the same type and name already exists in the registry.

..  function:: build_default_collector(type_name, name [, help])

    Register and return a collector for the middleware.

    :param string type_name: collector type: ``histogram`` or ``summary``. The default is ``histogram``.
    :param string      name: collector name. The default is ``http_server_request_latency``.
    :param string      help: collector description. The default is ``HTTP Server Request Latency``.

    :return: A collector object.

    **Possible errors:**

    *   A collector with the same type and name already exists in the registry.

..  function:: set_default_collector(collector)

    Set the default collector.

    :param collector: middleware collector object.

..  function:: get_default_collector()

    Return the default collector.
    If the default collector hasn't been set yet, register it (with default
    ``http_middleware.build_default_collector(...)`` parameters) and set it
    as default.

    :return: A collector object.

..  function:: v1(handler, collector)

    Latency measuring wrap-up for the HTTP ver. 1.x.x handler. Returns a wrapped handler.

    :param function handler: handler function.
    :param collector: middleware collector object.
                      If not set, the default collector is used
                      (like in ``http_middleware.get_default_collector()``).

    **Usage:** ``httpd:route(route, http_middleware.v1(request_handler, collector))``

    See `GitHub for a more detailed example <https://github.com/tarantool/metrics/blob/master/example/HTTP/latency_v1.lua>`__.

..  _metrics-api_reference-cpu_usage_metrics:

CPU usage metrics
-----------------

CPU metrics work only on Linux. See the :ref:`metrics reference <metrics-reference-psutils>`
for details.

To enable CPU metrics, first register a callback function:

..  code-block:: lua

    local metrics = require('metrics')

    metrics.register_callback(function()
        local cpu_metrics = require('metrics.psutils.cpu')
        cpu_metrics.update()
    end)

**Collected metrics example:**

..  code-block:: none

    # HELP tnt_cpu_time Host CPU time
    # TYPE tnt_cpu_time gauge
    tnt_cpu_time 15006759
    # HELP tnt_cpu_thread Tarantool thread cpu time
    # TYPE tnt_cpu_thread gauge
    tnt_cpu_thread{thread_name="coio",file_name="init.lua",thread_pid="699",kind="system"} 160
    tnt_cpu_thread{thread_name="tarantool",file_name="init.lua",thread_pid="1",kind="user"} 949
    tnt_cpu_thread{thread_name="tarantool",file_name="init.lua",thread_pid="1",kind="system"} 920
    tnt_cpu_thread{thread_name="coio",file_name="init.lua",thread_pid="11",kind="user"} 79
    tnt_cpu_thread{thread_name="coio",file_name="init.lua",thread_pid="699",kind="user"} 44
    tnt_cpu_thread{thread_name="coio",file_name="init.lua",thread_pid="11",kind="system"} 294

**Prometheus query aggregated by thread name:**

..  code-block:: text

    sum by (thread_name) (idelta(tnt_cpu_thread[$__interval]))
      / scalar(idelta(tnt_cpu_total[$__interval]) / tnt_cpu_count)

.. _metrics-api_reference-example:

Examples
--------

Below are some examples of using metric primitives.

Notice that this usage is independent of export plugins such as
Prometheus, Graphite, etc. For documentation on how to use the plugins, see
the :ref:`Metrics plugins <metrics-plugins>` section.

**Using counters:**

..  code-block:: lua

    local metrics = require('metrics')

    -- create a counter
    local http_requests_total_counter = metrics.counter('http_requests_total')

    -- somewhere in the HTTP requests middleware:
    http_requests_total_counter:inc(1, {method = 'GET'})

**Using gauges:**

..  code-block:: lua

    local metrics = require('metrics')

    -- create a gauge
    local cpu_usage_gauge = metrics.gauge('cpu_usage', 'CPU usage')

    -- register a lazy gauge value update
    -- this will be called whenever export is invoked in any plugins
    metrics.register_callback(function()
        local current_cpu_usage = some_cpu_collect_function()
        cpu_usage_gauge:set(current_cpu_usage, {app = 'tarantool'})
    end)

**Using histograms:**

..  code-block:: lua

    local metrics = require('metrics')
    local fiber = require('fiber')
    -- create a histogram
    local http_requests_latency_hist = metrics.histogram(
        'http_requests_latency', 'HTTP requests total', {2, 4, 6})

    -- somewhere in the HTTP request middleware:

    local t0 = fiber.clock()
    observable_function()
    local t1 = fiber.clock()

    local latency = t1 - t0
    http_requests_latency_hist:observe(latency)

**Using summaries:**

..  code-block:: lua

    local metrics = require('metrics')
    local fiber = require('fiber')

    -- create a summary with a window of 5 age buckets and a bucket lifetime of 60 s
    local http_requests_latency = metrics.summary(
        'http_requests_latency', 'HTTP requests total',
        {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01},
        {max_age_time = 60, age_buckets_count = 5}
    )

    -- somewhere in the HTTP requests middleware:
    local t0 = fiber.clock()
    observable_function()
    local t1 = fiber.clock()

    local latency = t1 - t0
    http_requests_latency:observe(latency)
