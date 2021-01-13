.. _monitoring-getting-started:

================================================================================
Monitoring: getting started
================================================================================

.. _tarantool-metrics:

-------------------------------------------------------------------------------
Tarantool
-------------------------------------------------------------------------------

First, you need to install the ``metrics`` package:

.. code-block:: console

    $ cd ${PROJECT_ROOT}
    $ tarantoolctl rocks install metrics

Next, require it in your code:

.. code-block:: lua

    local metrics = require('metrics')

Set a global label for your metrics:

.. code-block:: lua

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

.. _cartridge-role:

-------------------------------------------------------------------------------
Cartridge role
-------------------------------------------------------------------------------

``cartridge.roles.metrics`` is a role for
`Tarantool Cartridge <https://github.com/tarantool/cartridge>`_.
It allows using default metrics in a Cartridge application and manage them
via configuration.

**Usage**

#. Add the ``metrics`` package to dependencies in the ``.rockspec`` file.
   Make sure that you are using version **0.3.0** or higher.

   .. code-block:: lua

       dependencies = {
           ...
           'metrics >= 0.3.0-1',
           ...
       }

#. If you are using versions **0.3.0-0.5.0** then add ``cartridge.roles.metrics``
   to the roles list in ``cartridge.cfg``
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

   And then enable it in interface:

   .. image:: images/role-enable.png
      :align: center

   Since version **0.6.0** metrics role is permanent and enabled on instances by default.

#. After role initialization, default metrics will be enabled and the global
   label ``'alias'`` will be set. **Note** that ``'alias'`` label is set by
   configuration option ``alias``.

   If you need to use the functionality of any
   metrics package, you may get it as a Cartridge service and use it like
   a regular package after ``require``:

   .. code-block:: lua

       local cartridge = require('cartridge')
       local metrics = cartridge.service_get('metrics')

#. To view metrics via API endpoints, use the following configuration
   (to learn more about Cartridge configuration, see
   `this <https://www.tarantool.io/en/doc/latest/book/cartridge/topics/clusterwide-config/#managing-role-specific-data>`_):

   .. code-block:: yaml

       metrics:
         export:
         - path: '/path_for_json_metrics'
           format: 'json'
         - path: '/path_for_prometheus_metrics'
           format: 'prometheus'

   .. image:: images/role-config.png
      :align: center

   **OR**

   Use ``set_export``:

   **NOTE** that ``set_export`` has lower priority than clusterwide config and won't work if metrics config is present.

   .. code-block:: lua

       metrics.set_export({
           {
               path = '/path_for_json_metrics',
               format = 'json'
           },
           {
               path = '/path_for_prometheus_metrics',
               format = 'prometheus'
           }
       })

   The metrics will be available on the path specified in ``path`` in the format
   specified in ``format``.

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
