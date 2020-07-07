.. _plugins:

===============================================================================
Metrics Plugins
===============================================================================

Plugins allow to use an unified interface to collect metrics without
worrying about the way metrics export performed.
If you want to use another DB to store metrics data, you can use
appropriate export plugin just by changing one line of code-block.

.. _avaliable-plugins:

-------------------------------------------------------------------------------
Avaliable Plugins
-------------------------------------------------------------------------------

.. _prometheus:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Prometheus
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Usage**

Import the Prometheus plugin:

.. code-block:: lua

    local prometheus = require('metrics.plugins.prometheus')

Further, use the ``prometheus.collect_http()`` function, which returns:

.. code-block:: lua

    {
        status = 200,
        headers = <headers>,
        body = <body>,
    }

See the `Prometheus exposition format <https://github.com/prometheus/docs/blob/master/content/docs/instrumenting/exposition_formats.md>`__
for details on ``<body>`` and ``<headers>``.

Use in Tarantool `http.server <https://github.com/tarantool/http/>`__ as follows:

-  in Tarantool `http.server v1 <https://github.com/tarantool/http/tree/tarantool-1.6>`__
   (currently used in `Tarantool Cartridge <https://github.com/tarantool/cartridge>`__):

    .. code-block:: lua

        local httpd = require('http.server').new(...)
        ...
        httpd:route( { path = '/metrics' }, prometheus.collect_http)

-  in Tarantool `http.server v2 <https://github.com/tarantool/http/>`__ (the latest version):

    .. code-block:: lua

        local httpd = require('http.server').new(...)
        local router = require('http.router').new(...)
        httpd:set_router(router)
        ...
        router:route( { path = '/metrics' }, prometheus.collect_http)

**Sample settings**

-  for Tarantool ``http.server`` v1:

    .. code-block:: lua

        metrics = require('metrics')
        metrics.enable_default_metrics()
        prometheus = require('metrics.plugins.prometheus')
        httpd = require('http.server').new('0.0.0.0', 8080)
        httpd:route( { path = '/metrics' }, prometheus.collect_http)
        httpd:start()

-  for Tarantool Cartridge (with ``http.server`` v1):

    .. code-block:: lua

        cartridge = require('cartridge')
        httpd = cartridge.service_get('httpd')
        metrics = require('metrics')
        metrics.enable_default_metrics()
        prometheus = require('metrics.plugins.prometheus')
        httpd:route( { path = '/metrics' }, prometheus.collect_http)

-  for Tarantool ``http.server`` v2:

    .. code-block:: lua

        metrics = require('metrics')
        metrics.enable_default_metrics()
        prometheus = require('metrics.plugins.prometheus')
        httpd = require('http.server').new('0.0.0.0', 8080)
        router = require('http.router').new({charset = "utf8"})
        httpd:set_router(router) router:route( { path = '/metrics' },
        prometheus.collect_http)
        httpd:start()

.. _graphite:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Graphite
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Usage**

Import graphite plugin module:

.. code-block:: lua

    local graphite = require('metrics.plugins.graphite')

To start automatically exporting current values of all ``metrics.{counter,gauge,histogram}`` just call:

.. module:: metrics.plugins.graphite

.. function:: init(options)

    Create and start a ``my_fiber`` object. The object is created and begins to
    run immediately.

    :param table options:
        Possible options:
        -  ``prefix`` (string) - metrics prefix (default is ``'tarantool'``);
        -  ``host`` (string) - graphite server host (default is ``'127.0.0.1'``);
        -  ``port`` (number) - graphite server port (default is ``2003``);
        -  ``send_interval`` (number) - metrics collect interval in seconds
        (default is ``2``);

    This creates a background fiber, that periodically sends all metrics to
    remote Graphite server.

    Exported metric name is sent in format ``<prefix>.<metric_name>``.

.. _json:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
JSON
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Usage**

Import json plugin:

.. code-block:: lua

    local json_metrics = require('metrics.plugins.json')

.. module:: metrics.plugins.json

.. function:: export()

    :return:

        .. code-block:: json
            [
                {
                    "name":<name>,
                    "label_pairs": {
                        <name>:<value>,
                        ...
                    },
                    "timestamp":<number>,
                    "value":<value>
                },
                ...
            ]
    :rtype: string

    **Important** - values can be ``+-math.huge``, ``math.huge * 0``
    Then:
    ``math.inf`` serialized to ``"inf"``
    ``-math.inf`` serialized to ``"-inf"``
    ``nan`` serialized to ``"nan"``

    **Example**

    .. code-block:: json

        [
            {
                "label_pairs":{
                    "type":"nan"
                },
                "timestamp":1559211080514607,
                "metric_name":"test_nan",
                "value":"nan"
            },
            {
                "label_pairs":{
                    "type":"-inf"
                },
                "timestamp":1559211080514607,
                "metric_name":"test_inf",
                "value":"-inf"
            },
            {
                "label_pairs":{
                    "type":"inf"
                },
                "timestamp":1559211080514607,
                "metric_name":"test_inf",
                "value":"inf"
            }
        ]


To be used in Tarantool ``http.server`` as follows:

.. code-block:: lua

    local httpd = require('http.server').new(...)
    ...
    httpd:route({
            method = 'GET',
            path = '/metrics',
            public = true,
        },
        function(req)
            return req:render({
                text = json_exporter.export()
            })
        end
    )

.. _plugin-specific-api:

-------------------------------------------------------------------------------
Plugin-Specific API
-------------------------------------------------------------------------------

We encourage you to use following methods **only when developing new
plugin**.

.. module:: metrics

    .. function:: invoke_callbacks()
        Invokes function registered via ``metrics.register_callback(<callback>)``. Used in exporters.

    .. function:: collectors()

        Designed to be used in exporters in favor of ``metrics.collect()``.
        :return: a list of created collectors.

    .. class:: collector_object
        .. method:: collect()

            **NOTE**: You'll probably want to use `metrics.collectors()` instead.
            Equivalent to:
            .. code-block:: lua
                for _, c in pairs(metrics.collectors()) do
                    for _, obs in ipairs(c:collect()) do
                        ...  -- handle observation
                    end
                end
            :return:
                Concatenation of ``observation`` objects across all collectors created.

                .. code-block:: lua
                    {
                        label_pairs: table,         -- `label_pairs` key-value table
                        timestamp: ctype<uint64_t>, -- current system time (in microseconds)
                        value: number,              -- current value
                        metric_name: string,        -- collector
                    }

            :rtype: table

.. _writing-custom-plugins:

-------------------------------------------------------------------------------
Writing custom plugins
-------------------------------------------------------------------------------

Inside your main export function:

.. code-block:: lua

    -- Invoke all callbacks registered via `metrics.register_callback(<callback-function>)`.
    metrics.invoke_callbacks()

    -- Loop over collectors
    for _, c in pairs(metrics.collectors()) do
        ...

        -- Loop over instant observations in collector.
        for _, obs in pairs(c:collect()) do
            -- Export observation `obs`
            ...
        end

    end
