..  _monitoring-getting_started:

Monitoring: getting started
===========================

If you use Tarantool version below `2.11.1 <https://github.com/tarantool/tarantool/releases/tag/2.11.1>`__,
it is necessary to install the latest version of ``metrics`` first. For details,
see :ref:`Installing the metrics module <install>`.

.. _monitoring-getting_started-how_to_use:

Using the metrics module
------------------------

..  note::

    The module is also used in applications based on the Cartridge framework. For details,
    see the :ref:`Getting started with Cartridge <getting_started_cartridge>` section.


#.  First, set the instance name and start to collect the standard set of metrics.
    Also, you can set a global label for your instance.

    ..  code-block:: lua

        metrics.cfg(labels = {alias = 'my-instance'})

    When using a metrics module version below **0.17.0**, use the following snippet instead of ``metrics.cfg(...)``:

    ..  code-block:: lua

        metrics.set_global_labels({alias = 'my-instance'})
        metrics.enable_default_metrics()


#.  Add a handler to expose metric values.

    For JSON format:

    ..  code-block:: lua

        local json_exporter = require('metrics.plugins.json')
        local function http_metrics_handler(request)
            return request:render({ text = json_exporter.export() })
        end

    For Prometheus format:

    ..  code-block:: lua

        local prometheus_exporter = require('metrics.plugins.prometheus').collect_http


    To learn how to extend metrics with custom data, check the :ref:`API reference <metrics-api_reference>`.

#.  Start the HTTP server and expose metrics:

    ..  code-block:: lua

        local http_server = require('http.server')
        local server = http_server.new('0.0.0.0', 8081)
        server:route({path = '/metrics'}, http_metrics_handler)
        server:start()

#.  In the end, you will be able to see the metric values by accessing the URL ``http://localhost:8081/metrics``:

    ..  code-block:: json

        [
          {
            "label_pairs": {
              "alias": "my-instance"
            },
            "timestamp": 1679663602823779,
            "metric_name": "tnt_vinyl_disk_index_size",
            "value": 0
          },
          . . .
          {
            "label_pairs": {
              "alias": "my-instance"
            },
            "timestamp": 1679663602823779,
            "metric_name": "tnt_info_memory_data",
            "value": 39272
          },
          {
            "label_pairs": {
              "alias": "my-instance"
            },
            "timestamp": 1679663602823779,
            "metric_name": "tnt_election_vote",
            "value": 0
          }
        ]

The data can be visualized in
`Grafana dashboard <https://www.tarantool.io/en/doc/latest/book/monitoring/grafana_dashboard/#monitoring-grafana-dashboard-page>`__.

.. _monitoring-getting_started-full_source_example:

Full source example:

.. code-block:: lua

    -- Import modules
    local metrics = require('metrics')
    local http_server = require('http.server')
    local json_exporter = require('metrics.plugins.json')

    -- Define helper functions
    local function http_metrics_handler(request)
        return request:render({ text = json_exporter.export() })
    end

    -- Start the database
    box.cfg{
        listen = 3301,
    }

    -- Configure the metrics module
    metrics.cfg(labels = {alias = 'my-tnt-app'})

    -- Run the web server
    local server = http_server.new('0.0.0.0', 8081)
    server:route({path = '/metrics'}, http_metrics_handler)
    server:start()

..  _monitoring-getting_started-http_metrics:

Collecting HTTP metrics
-----------------------

To enable the collection of HTTP metrics, wrap a handler with a ``metrics.http_middleware.v1`` function:

..  code-block:: lua

    local metrics = require('metrics')
    local httpd = require('http.server').new(ip, port)

    -- Create a summary collector for latency
    local default_collector = metrics.http_middleware.build_default_collector('summary')
    metrics.http_middleware.set_default_collector(default_collector)

    -- Set a route handler for latency summary collection
    httpd:route({ path = '/path-1', method = 'POST' }, metrics.http_middleware.v1(handler_1, collector))
    httpd:route({ path = '/path-2', method = 'GET' }, metrics.http_middleware.v1(handler_2, collector))

    -- Start HTTP routing
    httpd:start()

.. note::

    By default, the ``http_middleware`` uses the ``histogram`` collector for backward compatibility reasons.
    To collect HTTP metrics, use the ``summary`` type instead.


You can collect all HTTP metrics with a single collector.
If you use the default
:ref:`Grafana dashboard <monitoring-grafana_dashboard-page>`,
don't change the default collector name.
Otherwise, your metrics won't appear on the charts.

..  _monitoring-getting_started-custom_metric:

Creating custom metric
----------------------

You can create your own metric in two ways, depending on when you need to take measurements:

*   at any arbitrary moment of time
*   when the data collected by metrics is requested

To create custom metrics at any arbitrary moment of time, do the following:

#. Create the collector:

..  code-block:: lua

    local response_counter = metrics.counter('response_counter', 'Response counter')

#. Take a measurement at the appropriate place, for example, in an API request handler:

..  code-block:: lua

    local function check_handler(request)
        local label_pairs = {
            path = request.path,
            method = request.method,
        }
        response_counter:inc(1, label_pairs)
        -- ...
    end

To create custom metrics when the data collected by metrics is requested, do the following

#. Create the collector:

..  code-block:: lua

    local other_custom_metric = metrics.gauge('other_custom_metric', 'Other custom metric')

#. Take a measurement at the time of requesting the data collected by the metrics:

..  code-block:: lua

    metrics.register_callback(function()
        -- ...
        local label_pairs = {
            category = category,
        }
        other_custom_metric:set(current_value, label_pairs)
    end)

The full example is listed below.

..  code-block:: lua

    -- Import modules
    local metrics = require('metrics')
    local http_server = require('http.server')
    local json_exporter = require('metrics.plugins.json')

    local response_counter = metrics.counter('response_counter', 'Response counter')

    -- Define helper functions
    local function http_metrics_handler(request)
        return request:render({ text = json_exporter.export() })
    end

    local function check_handler(request)
        local label_pairs = {
            path = request.path,
            method = request.method,
        }
        response_counter:inc(1, label_pairs)
        return request:render({ text = 'ok' })
    end

    -- Start the database
    box.cfg{
        listen = 3301,
    }

    -- Configure the metrics module
    metrics.set_global_labels{alias = 'my-tnt-app'}

    -- Run the web server
    local server = http_server.new('0.0.0.0', 8081)
    server:route({path = '/metrics'}, http_metrics_handler)
    server:route({path = '/check'}, check_handler)
    server:start()

The result looks in the following way:

    ..  code-block:: json

    [
      {
        "label_pairs": {
          "path": "/check",
          "method": "GET",
          "alias": "my-tnt-app"
        },
        "timestamp": 1688385933874080,
        "metric_name": "response_counter",
        "value": 1
      }
    ]

..  _monitoring-getting_started-warning:

Warning
~~~~~~~

The module allows to add your own metrics, but there are nuances when working with
specific tools.

When adding your custom metric, it's important to ensure that the number of label value combinations is
kept to a minimum. Otherwise, combinatorial explosion may happen in the timeseries database with metrics values
stored. Examples of data labels:

*   Labels in Prometheus
*   Tags in InfluxDB

For example, if your company uses InfluxDB for metric collection, you could potentially disrupt the entire
monitoring setup, both for your application and for all other systems within the company. As a result,
monitoring data is likely to be lost.

Example:

..  code-block:: lua

    local some_metric = metrics.counter('some', 'Some metric')

    -- THIS IS POSSIBLE
    local function on_value_update(instance_alias)
       some_metric:inc(1, { alias = instance_alias })
    end

    -- THIS IS NOT ALLOWED
    local function on_value_update(customer_id)
       some_metric:inc(1, { customer_id = customer_id })
    end

In the example, there are two versions of the function ``on_value_update``. The top version labels
the data with the cluster instance's alias. Since there's a relatively small number of nodes, using
them as labels is feasible. In the second case, an identifier of a record is used. If there are many
records, it's recommended to avoid such situations.

The same principle applies to URLs. Using the entire URL with parameters is not recommended.
Use an URL template or the name of the command instead.

In essence, when designing custom metrics and selecting labels or tags, it's crucial to opt for a minimal
set of values that can uniquely identify the data without introducing unnecessary complexity or potential
conflicts with existing metrics and systems.
