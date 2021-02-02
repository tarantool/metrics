.. _monitoring-getting-started:

================================================================================
Monitoring: getting started
================================================================================

.. _tarantool-metrics:

-------------------------------------------------------------------------------
Tarantool
-------------------------------------------------------------------------------

First, you need to install the ``metrics`` package:

..  code-block:: console

    $ cd ${PROJECT_ROOT}
    $ tarantoolctl rocks install metrics

Next, require it in your code:

..  code-block:: lua

    local metrics = require('metrics')

Set a global label for your metrics:

..  code-block:: lua

    metrics.set_global_labels({alias = 'alias'})

Enable default Tarantool metrics such as network, memory, operations, etc:

.. code-block:: lua

    metrics.enable_default_metrics()

If you use Cartridge, enable Cartridge metrics:

.. code-block:: lua

    metrics.enable_cartridge_metrics()

Initialize the Prometheus Exporter, or export metrics in any other format:

.. code-block:: lua

    local httpd = require('http.server')
    local http_handler = require('metrics.plugins.prometheus').collect_http


    httpd.new('0.0.0.0', 8088)
        :route({path = '/metrics'}, function(...)
            return http_handler(...)
    end)
        :start()

    box.cfg{
        listen = 3302
    }

Now you can use the HTTP API endpoint ``/metrics`` to collect your metrics
in the Prometheus format. If you need your custom metrics, see the
:ref:`API reference <metrics-api-reference>`.

.. _instance-health-check:

-------------------------------------------------------------------------------
Instance health check
-------------------------------------------------------------------------------

In production environments Tarantool Cluster usually has a large number of so called
"routers", Tarantool instances that handle input load and it is required to evenly 
distribute the load. Various load-balancers are used for this, but any load-balancer 
have to know which "routers" are ready to accept the load at that very moment. Metrics 
library has a special plugin that creates an http handler that can be used by the 
load-balancer to check the current state of any Tarantool instance. If the instance 
is ready to accept the load, it will return a response with a 200 status code, if not, 
with a 500 status code.

.. _cartridge-role:

-------------------------------------------------------------------------------
Cartridge role
-------------------------------------------------------------------------------

``cartridge.roles.metrics`` is a role for
`Tarantool Cartridge <https://github.com/tarantool/cartridge>`_.
It allows using default metrics in a Cartridge application and manage them
via configuration.

**Usage**

#. Add ``metrics`` package to dependencies in the ``.rockspec`` file.
   Make sure that you are using version **0.3.0** or higher.

   .. code-block:: lua

       dependencies = {
           ...
           'metrics >= 0.3.0-1',
           ...
       }

#. Make sure that you have ``cartridge.roles.metrics``
   in the roles list in ``cartridge.cfg``
   in your entry-point file (e.g. ``init.lua``).

   .. code-block:: lua

       local ok, err = cartridge.cfg({
           ...
           roles = {
               ...
               'cartridge.roles.metrics',
               ...
           },
       })

#. Enable role in the interface:

   .. image:: images/role-enable.png
      :align: center

   Since version **0.6.0** metrics role is permanent and enabled on instances by default.

#. After role initialization, default metrics will be enabled and the global
   label ``'alias'`` will be set. **Note** that ``'alias'`` label value is set by
   instance :ref:`configuration option <cartridge-config>` ``alias`` or ``instance_name`` (since **0.6.1**).

   If you need to use the functionality of any
   metrics package, you may get it as a Cartridge service and use it like
   a regular package after ``require``:

   .. code-block:: lua

       local cartridge = require('cartridge')
       local metrics = cartridge.service_get('metrics')

#. To view metrics via API endpoints, use the following configuration
   (to learn more about Cartridge configuration, see
   `this <https://www.tarantool.io/en/doc/latest/book/cartridge/topics/clusterwide-config/#managing-role-specific-data>`_):

   ..  code-block:: yaml

       metrics:
         export:
         - path: '/path_for_json_metrics'
           format: 'json'
         - path: '/path_for_prometheus_metrics'
           format: 'prometheus'
         - path: '/health'
           format: 'health'

   .. image:: images/role-config.png
      :align: center

   **OR**

   Use ``set_export``:

   **NOTE** that ``set_export`` has lower priority than clusterwide config and won't work if metrics config is present.

   ..  code-block:: lua

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

   The metrics will be available on the path specified in ``path`` in the format
   specified in ``format``.

   You can add several entry points of the same format by different paths,
   like this:

   ..  code-block:: yaml

       metrics:
         export:
           - path: '/path_for_json_metrics'
             format: 'json'
           - path: '/another_path_for_json_metrics'
             format: 'json'

.. _grafana-dashboard:

-------------------------------------------------------------------------------
Grafana dashboard
-------------------------------------------------------------------------------

Tarantool Grafana dashboard is available as part of
`Grafana Official & community built dashboards <https://grafana.com/grafana/dashboards>`_.
You can find version for Prometheus datasource on
`this page <https://grafana.com/grafana/dashboards/13054>`_ and version for
InfluxDB datasource on `this page <https://grafana.com/grafana/dashboards/12567>`_.
Tarantool Grafana dashboard is a ready for import template with basic memory, space operations
and HTTP load panels, based on default ``metrics`` package functionality.

Dashboards require using ``metrics`` **0.5.0** or newer;
``'alias'`` :ref:`global label <tarantool-metrics>` must be set on each instance
to properly display panels (e.g. provided with ``cartridge.roles.metrics`` role).

**Usage**

#.  Set up your monitoring stack. Since there are `Prometheus <https://prometheus.io/>`_
    and `InfluxDB <https://www.influxdata.com/>`_ datasource Grafana dashboards,
    you can use
   
    - `Telegraf <https://www.influxdata.com/time-series-platform/telegraf/>`_
      as a server agent for collecting metrics, `InfluxDB <https://www.influxdata.com/>`_
      as a time series database for storing metrics, `Grafana <https://grafana.com/>`_
      as a visualization platform; or
    - `Prometheus <https://prometheus.io/>`_ as both server agent for collecting metrics
      and time series database for storing metrics, `Grafana <https://grafana.com/>`_
      as a visualization platform.

    For issues concerning set up of Prometheus, Telegraf, InfluxDB or Grafana instances
    please refer to corresponding project's documentation.

#.  Configure your Tarantool instances to output metrics with proper format
    and configure corresponding server agent to collect them.

    To collect metrics for Prometheus, first off you must set up metrics output with
    ``prometheus`` format. You can use :ref:`cartridge.roles.metrics <cartridge-role>`
    configuration or set up :ref:`output plugin <prometheus>` manually.
    To start collecting metrics, add a `job <https://prometheus.io/docs/prometheus/latest/getting_started/#configure-prometheus-to-monitor-the-sample-targets>`_
    to Prometheus configuration with each Tarantool instance URI as a target and
    metrics path as it was configured on Tarantool instances:

    ..  code-block:: yaml

        scrape_configs:
          - job_name: "example_project"
            static_configs:
              - targets: 
                - "example_project:8081"
                - "example_project:8082"
                - "example_project:8083"
            metrics_path: "/metrics/prometheus"

    To collect metrics for InfluxDB, you must use Telegraf agent.
    First off, configure Tarantool metrics output in ``json`` format
    with :ref:`cartridge.roles.metrics <cartridge-role>` configuration or
    corresponding :ref:`output plugin <json>`. To start collecting metrics,
    add `http input <https://github.com/influxdata/telegraf/blob/release-1.17/plugins/inputs/http/README.md>`_
    to Telegraf configuration including each Tarantool instance metrics URL:

    ..  code-block:: text

        [[inputs.http]]
            urls = [
                "http://example_project:8081/metrics/json",
                "http://example_project:8082/metrics/json",
                "http://example_project:8083/metrics/json"
            ]
            timeout = "30s"
            tag_keys = [
                "metric_name",
                "label_pairs_alias",
                "label_pairs_quantile",
                "label_pairs_path",
                "label_pairs_method",
                "label_pairs_status",
                "label_pairs_operation"
            ]
            insecure_skip_verify = true
            interval = "10s"
            data_format = "json"
            name_prefix = "example_project_"
            fieldpass = ["value"]

    Be sure to include each label key as ``label_pairs_<key>`` so it will be
    extracted with plugin. For example, if you use :code:`{ state = 'ready' }` labels
    somewhere in metric collectors, add ``label_pairs_state`` tag key.

    If you connect Telegraf instance to InfluxDB storage, metrics will be stored
    with ``"<name_prefix>http"`` measurement (``"example_project_http"`` in our example).

#.  Import a dashboard from `Grafana Official & community built dashboards <https://grafana.com/grafana/dashboards>`_.

    Open Grafana import menu.

    ..  image:: images/grafana-import-v6.png
        :align: center

    To import specific dashboard, choose one of the following options:

    - paste dashboard id (``12567`` for InfluxDB dashboard, ``13054`` for Prometheus dashboard), or
    - paste link to dashboard (https://grafana.com/grafana/dashboards/12567 for InfluxDB dashboard,
      https://grafana.com/grafana/dashboards/13054 for Prometheus dashboard), or
    - paste dashboard json file contents, or
    - upload dashboard json file.

    Set dashboard name, folder, uid (if needed), and datasource-related query parameters
    (InfluxDB source, measurement and policy or Prometheus source, job and rate time range).

    ..  image:: images/grafana-import-setup-v6.png
        :align: center

    If no data present on graphs, ensure that you set up datasource and job/measurement correctly.
    If no data present on rps graphs on Prometheus table, ensure that
    your rate time range parameter is at least twice as Prometheus scrape interval.
