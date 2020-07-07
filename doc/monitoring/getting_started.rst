.. _monitoring-getting-started:

================================================================================
Monitoring: getting started
================================================================================

.. _tarantool-metrics:

-------------------------------------------------------------------------------
Tarantool
-------------------------------------------------------------------------------

First, you need to install metrics package:

.. code-block:: bash

    cd ${PROJECT_ROOT}
    tarantoolctl rocks install metrics


Next, require it in your code:

.. code-block:: lua

    local metrics = require('metrics')

Set global label to your metrics:

.. code-block:: lua

    metrics.set_global_labels({alias = 'alias'})

Enable default tarantool metrics such as network, memory, operations, etc:

.. code-block:: lua

    metrics.enable_default_metrics()

Init Prometheus Exporter, or export metrics in any other format:

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

Now you can use HTTP API endpoint ``/metrics`` to collect your metrics in Prometheus format. If you need your custom metrics, see API reference.

.. _cartridge-role:

-------------------------------------------------------------------------------
Cartridge role
-------------------------------------------------------------------------------

``cartridge.roles.metrics`` is a role for `tarantool/cartridge <https://github.com/tarantool/cartridge>`__. It allows to use default metrics in a Cartridge application and manage them via configuration.

**Usage**

#. Add the ``metrics`` package to dependencies in the ``.rockspec`` file. Make sure that you are using version 0.3.0 or higher.

    .. code-block:: lua

        dependencies = {
            ...
            'metrics >= 0.3.0-1',
            ...
        }

#. Add ``cartridge.roles.metrics`` to the roles list in ``cartridge.cfg`` in your entry-point file (e.g. ``init.lua``).

    .. code-block:: lua

        local ok, err = cartridge.cfg({
            ...
            roles = {
                ...
                'cartridge.roles.metrics',
                ...
            },
        })

#. After role initialization, default metrics will be enabled and the global label 'alias' will be set. If you need to use the functionality of any metrics package, you may get it as a Cartridge service and use it like a regular package after ``require``:

    .. code-block:: lua

        local cartridge = require('cartridge')
        local metrics = cartridge.service_get('metrics')

#. To view metrics via API endpoints, use the following configuration (to learn more about Cartridge configuration, see `this <https://www.tarantool.io/en/doc/2.3/book/cartridge/topics/clusterwide-config/#managing-role-specific-data>`__):

    .. code-block:: yaml

        metrics:
          export:
          - path: '/path_for_json_metrics'
            format: 'json'
          - path: '/path_for_prometheus_metrics'
            format: 'prometheus'

You can add several entry points of the same format by different paths,
like this:

.. code-block:: yaml

    metrics:
      export:
        - path: '/path_for_json_metrics'
          format: 'json'
        - path: '/another_path_for_json_metrics'
          format: 'json'

.. _grafana-dashboard:

-------------------------------------------------------------------------------
Grafana Dashboard
-------------------------------------------------------------------------------

...
