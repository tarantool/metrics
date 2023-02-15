..  _metrics-plugins:

Metrics plugins
===============

Plugins let you collect metrics through a unified interface
without worrying about the way metrics export works.
If you want to use another DB to store metrics data, you can enable an
appropriate export plugin just by changing one line of code.

..  _metrics-plugins-available:

Available plugins
-----------------

Prometheus
~~~~~~~~~~

Usage
^^^^^

Import the plugin:

..  code-block:: lua

    local prometheus = require('metrics.plugins.prometheus')

Then use the ``prometheus.collect_http()`` function, which returns:

..  code-block:: lua

    {
        status = 200,
        headers = <headers>,
        body = <body>,
    }

See the
`Prometheus exposition format <https://github.com/prometheus/docs/blob/master/content/docs/instrumenting/exposition_formats.md>`_
for details on ``<body>`` and ``<headers>``.

With Tarantool `http.server <https://github.com/tarantool/http/>`__,
use this plugin as follows:

..  code-block:: lua

    local httpd = require('http.server').new(...)
    ...
    httpd:route( { path = '/metrics' }, prometheus.collect_http)


Sample settings
^^^^^^^^^^^^^^^

*   For Tarantool:

    ..  code-block:: lua

        metrics = require('metrics')
        metrics.cfg{}
        prometheus = require('metrics.plugins.prometheus')
        httpd = require('http.server').new('0.0.0.0', 8080)
        httpd:route( { path = '/metrics' }, prometheus.collect_http)
        httpd:start()

*   For Tarantool Cartridge:

    ..  code-block:: lua

        cartridge = require('cartridge')
        httpd = cartridge.service_get('httpd')
        metrics = require('metrics')
        metrics.cfg{}
        prometheus = require('metrics.plugins.prometheus')
        httpd:route( { path = '/metrics' }, prometheus.collect_http)


Graphite
~~~~~~~~

Usage
^^^^^

Import the plugin:

..  code-block:: lua

    local graphite = require('metrics.plugins.graphite')

To start automatically exporting the current values of all
``metrics.{counter,gauge,histogram}``, call the following function:

..  module:: metrics.plugins.graphite

..  function:: init(options)

    :param table options: possible options:

                          *  ``prefix`` (string): metrics prefix (``'tarantool'`` by default)
                          *  ``host`` (string): Graphite server host (``'127.0.0.1'`` by default)
                          *  ``port`` (number): Graphite server port (``2003`` by default)
                          *  ``send_interval`` (number): metrics collection interval in seconds
                             (``2`` by default)

    This function creates a background fiber that periodically sends all metrics to
    a remote Graphite server.

    Exported metric names are formatted as follows: ``<prefix>.<metric_name>``.

JSON
~~~~

Usage
^^^^^

Import the plugin:

..  code-block:: lua

    local json_metrics = require('metrics.plugins.json')

..  module:: metrics.plugins.json

..  function:: export()

    :return: the following structure

        ..  code-block:: json

            [
                {
                    "name": "<name>",
                    "label_pairs": {
                        "<name>": "<value>",
                        "...": "..."
                        },
                    "timestamp": "<number>",
                    "value": "<value>"
                },
                "..."
            ]

    :rtype: string

    ..  IMPORTANT::

        The values can also be ``+-math.huge`` and ``math.huge * 0``. In such case:

        *   ``math.huge`` is serialized to ``"inf"``
        *   ``-math.huge`` is serialized to ``"-inf"``
        *   ``math.huge * 0`` is serialized to ``"nan"``.

    **Example**

    ..  code-block:: json

        [
            {
                "label_pairs": {
                    "type": "nan"
                },
                "timestamp": 1559211080514607,
                "metric_name": "test_nan",
                "value": "nan"
            },
            {
                "label_pairs": {
                    "type": "-inf"
                },
                "timestamp": 1559211080514607,
                "metric_name": "test_inf",
                "value": "-inf"
            },
            {
                "label_pairs": {
                    "type": "inf"
                },
                "timestamp": 1559211080514607,
                "metric_name": "test_inf",
                "value": "inf"
            }
        ]

Use the JSON plugin with Tarantool ``http.server`` as follows:

..  code-block:: lua

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

Flight recorder
~~~~~~~~~~~~~~~

Usage
^^^^^

Import the plugin:

..  code-block:: lua

    local flight_recorder_exporter = require('metrics.plugins.flight_recorder')

..  module:: metrics.plugins.flight_recorder

..  function:: export()

    :return: extended format output with aggregates

        ..  code-block:: yaml

            - tnt_net_per_thread_connections_mingauge:
                name: tnt_net_per_thread_connections_min
                name_prefix: tnt_net_per_thread_connections
                kind: gauge
                metainfo:
                  aggregate: true
                  default: true
                timestamp: 1676478112824745
                observations:
                  '':
                    "thread\t1":
                      label_pairs:
                        thread: '1'
                      value: 0
            ...

..  function:: plain_format(output)

    :return: human-readable form of output

        ..  code-block:: text

            tnt_info_memory_lua_max{alias=router-4} 10237204
            tnt_info_memory_lua_min{alias=router-4} 1921790
            tnt_info_memory_lua{alias=router-4} 2733335
            tnt_info_uptime{alias=router-4} 1052
            ...

.. _metrics-plugins-custom:

Creating custom plugins
-----------------------

Include the following in your main export function:

..  code-block:: lua

    local metrics = require('metrics')
    local string_utils = require('metrics.string_utils')

    -- Collect up-to-date metrics with extended format.
    local output = metrics.collect{invoke_callbacks = true, extended_format = true}

    for _, coll_obs in pairs(output) do
        -- Serialize collector info like coll_obs.name, coll_obs.help,
        -- coll_obs.kind and coll_obs.timestamp

        for group_name, obs_group in pairs(coll_obs.observations) do
            -- Common way to build metric name.
            local metric_name = string_utils.build_name(coll_obs.name, group_name)

            for _, obs in pairs(obs_group) do
                -- Serialize observation info: obs.value and obs.label_pairs

            end
        end
    end
