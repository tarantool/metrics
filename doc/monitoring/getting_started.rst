..  _monitoring-getting_started:

Monitoring: getting started
===========================

.. _monitoring-getting_started-tarantool:

Tarantool
---------

First, install the ``metrics`` package:

..  code-block:: console

    $ cd ${PROJECT_ROOT}
    $ tarantoolctl rocks install metrics

Next, require it in your code:

..  code-block:: lua

    local metrics = require('metrics')

Enable default Tarantool metrics such as network, memory, operations, etc.
You may also set a global label for your metrics:

..  code-block:: lua

    metrics.cfg{labels = {alias = 'alias'}}

Initialize the Prometheus exporter or export metrics in another format:

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
in the Prometheus format. To learn how to obtain custom metrics, check the
:ref:`API reference <metrics-api_reference>`.

..  _monitoring-getting_started-http_metrics:

Collect HTTP metrics
--------------------

To enable the collection of HTTP metrics, you need to create a collector first.

..  code-block:: lua

    local httpd = require('http.server').new(ip, port)

    -- Create a summary collector for latency
    local collector = metrics.http_middleware.build_default_collector('summary')

    -- Set a route handler for latency summary collection
    httpd:route({ path = '/path-1', method = 'POST' }, metrics.http_middleware.v1(handler_1, collector))
    httpd:route({ path = '/path-2', method = 'GET' }, metrics.http_middleware.v1(handler_2, collector))

    -- Start HTTP routing
    httpd:start()

You can collect all HTTP metrics with a single collector.
If you're using the default
:ref:`Grafana dashboard <monitoring-grafana_dashboard-page>`,
don't change the default collector name.
Otherwise, your metrics won't appear on the charts.


.. _monitoring-getting_started-instance_health_check:

Instance health check
---------------------

In production environments, Tarantool Cartridge usually has a large number of so-called
routers -- Tarantool instances that handle input load.
Various load balancers help distribute that load evenly.
However, any load balancer has to know
which routers are ready to accept the load at the moment.
The Tarantool metrics library has a special plugin that creates an HTTP handler,
which the load balancer can use to check the current state of any Tarantool instance.
If the instance is ready to accept the load, it will return a response with a 200 status code,
and if not, with a 500 status code.

.. _monitoring-getting_started-cartridge_role:

Cartridge role
--------------

``cartridge.roles.metrics`` is a
`Tarantool Cartridge <https://github.com/tarantool/cartridge>`__ role.
It allows using default metrics in a Cartridge application and managing them
via Cartridge configuration.

**Usage**

#.  Add ``cartridge-metrics-role`` package to the dependencies in the ``.rockspec`` file.

    .. code-block:: lua

        dependencies = {
            ...
            'cartridge-metrics-role >= 0.1.0-1',
            ...
        }

    If you're using older version of metrics package, you need to add ``metrics`` package
    instead of ``cartridge-metrics-role``.

    .. code-block:: lua

        dependencies = {
            ...
            'metrics == 0.17.0-1',
            ...
        }

    Cartridge role is present in package versions from **0.3.0** to **0.17.0**.

#.  Make sure that ``cartridge.roles.metrics`` is included
    in the roles list in ``cartridge.cfg``
    in your entry point file (for example, ``init.lua``):

    .. code-block:: lua

        local ok, err = cartridge.cfg({
            ...
            roles = {
                ...
                'cartridge.roles.metrics',
                ...
            },
        })

#.  To get metrics via API endpoints, use ``set_export``.

    ..  note::

        ``set_export`` has lower priority than clusterwide configuration
        and may be overridden by the metrics configuration.

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

    You can add several endpoints of the same format with different paths.
    For example:

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

    The metrics will be available on the path specified in ``path``, in the format
    specified in ``format``.

#.  Since version **0.6.0**, the metrics role is permanent and enabled on instances by default.
    If you use old version of metrics, you should enable the role in the interface:

    ..  image:: images/role-enable.png
        :align: center

#.  After the role has been initialized, the default metrics will be enabled
    and the global label ``alias`` will be set.
    **Note** that the ``alias`` label value is set by the ``alias`` or ``instance_name``
    instance :ref:`configuration option <cartridge-config>` (since **0.6.1**).

    You can use the functionality of any
    metrics package by getting it as a Cartridge service
    and calling it with ``require`` like a regular package:

    ..  code-block:: lua

        local cartridge = require('cartridge')
        local metrics = cartridge.service_get('metrics')

#.  Since Tarantool Cartridge ``2.4.0``, you can set a zone for each
    instance in the cluster. When a zone is set, all the metrics on the instance
    receive the ``zone`` label.

#.  To change the HTTP path for a metric in **runtime**,
    you can use the configuration below.
    `Learn more about Cartridge configuration <https://www.tarantool.io/en/doc/latest/book/cartridge/cartridge_dev/#managing-role-specific-data>`_).
    It is not recommended to set up the metrics role in this way. Use ``set_export`` instead.

    ..  code-block:: yaml

        metrics:
          export:
            - path: '/path_for_json_metrics'
              format: 'json'
            - path: '/path_for_prometheus_metrics'
              format: 'prometheus'
            - path: '/health'
              format: 'health'

    ..  image:: images/role-config.png
        :align: center

#.  You can set custom global labels with the following configuration:

    ..  code-block:: yaml

        metrics:
          export:
            - path: '/metrics'
              format: 'json'
          global-labels:
            my-custom-label: label-value

    Another option is to invoke the ``set_default_labels`` function in ``init.lua``:

    ..  code-block:: lua

        local metrics = require('cartridge.roles.metrics')
        metrics.set_default_labels({ ['my-custom-label'] = 'label-value' })

#.  You can use the configuration below to choose the default metrics to be exported.
    If you add the include section, only the metrics from this section will be exported:

    ..  code-block:: yaml

        metrics:
          export:
            - path: '/metrics'
              format: 'json'
          # export only vinyl, luajit and memory metrics:
          include:
            - vinyl
            - luajit
            - memory

    If you add the exclude section,
    the metrics from this section will be removed from the default metrics list:

    ..  code-block:: yaml

        metrics:
          export:
            - path: '/metrics'
              format: 'json'
          # export all metrics except vinyl, luajit and memory:
          exclude:
            - vinyl
            - luajit
            - memory

    For the full list of default metrics, check the
    :ref:`API reference <metrics-api_reference-functions>`.
