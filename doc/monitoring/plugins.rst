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

*   With Tarantool `http.server v.1 <https://github.com/tarantool/http/tree/tarantool-1.6>`_
    (currently used in `Tarantool Cartridge <https://github.com/tarantool/cartridge>`_):

    ..  code-block:: lua

        local httpd = require('http.server').new(...)
        ...
        httpd:route( { path = '/metrics' }, prometheus.collect_http)

*   With Tarantool `http.server v.2 <https://github.com/tarantool/http/>`_
    (the latest version):

    ..  code-block:: lua

        local httpd = require('http.server').new(...)
        local router = require('http.router').new(...)
        httpd:set_router(router)
        ...
        router:route( { path = '/metrics' }, prometheus.collect_http)

Sample settings
^^^^^^^^^^^^^^^

*   For Tarantool ``http.server`` v.1:

    ..  code-block:: lua

        metrics = require('metrics')
        metrics.enable_default_metrics()
        prometheus = require('metrics.plugins.prometheus')
        httpd = require('http.server').new('0.0.0.0', 8080)
        httpd:route( { path = '/metrics' }, prometheus.collect_http)
        httpd:start()

*   For Tarantool Cartridge (with ``http.server`` v.1):

    ..  code-block:: lua

        cartridge = require('cartridge')
        httpd = cartridge.service_get('httpd')
        metrics = require('metrics')
        metrics.enable_default_metrics()
        prometheus = require('metrics.plugins.prometheus')
        httpd:route( { path = '/metrics' }, prometheus.collect_http)

*   For Tarantool ``http.server`` v.2:

    ..  code-block:: lua

        metrics = require('metrics')
        metrics.enable_default_metrics()
        prometheus = require('metrics.plugins.prometheus')
        httpd = require('http.server').new('0.0.0.0', 8080)
        router = require('http.router').new({charset = "utf8"})
        httpd:set_router(router) router:route( { path = '/metrics' },
        prometheus.collect_http)
        httpd:start()

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

..  _metrics-plugins-plugin-specific_api:

Plugin-specific API
-------------------

Use the following methods **only when developing a new plugin**.

..  module:: metrics

..  function:: invoke_callbacks()

    Invoke a function registered via
    ``metrics.register_callback(<callback>)``.
    Used in exporters.

..  function:: collectors()

    List all collectors in the registry. Designed to be used in exporters.

    :return: A list of created collectors.

..  class:: collector_object

    ..  method:: collect()

        ..  note::

            You'll probably want to use ``metrics.collectors()`` instead.

        Equivalent to:

        ..  code-block:: lua

            for _, c in pairs(metrics.collectors()) do
                for _, obs in ipairs(c:collect()) do
                    ...  -- handle observation
                end
            end

        :return: A concatenation of ``observation`` objects across all created collectors.

            ..  code-block:: lua

                {
                    label_pairs: table,         -- `label_pairs` key-value table
                    timestamp: ctype<uint64_t>, -- current system time (in microseconds)
                    value: number,              -- current value
                    metric_name: string,        -- collector
                }

        :rtype: table

.. _metrics-plugins-custom:

Creating custom plugins
-----------------------

Include the following in your main export function:

..  code-block:: lua

    -- Invoke all callbacks registered via `metrics.register_callback(<callback-function>)`
    metrics.invoke_callbacks()

    -- Loop over collectors
    for _, c in pairs(metrics.collectors()) do
        ...

        -- Loop over instant observations in the collector
        for _, obs in pairs(c:collect()) do
            -- Export observation `obs`
            ...
        end

    end
