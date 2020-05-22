## Prometheus

Plugin to collect metrics and send them to Prometheus server.

### API

Import Prometheus Plugin:

```lua
local prometheus = require('metrics.plugins.prometheus')
```

#### `prometheus.collect_http()`
See [Prometheus Exposition Format](https://github.com/prometheus/docs/blob/master/content/docs/instrumenting/exposition_formats.md) for details on `<body>` and `<headers>`.
Returns:
```lua
{
    status = 200,
    headers = <headers>,
    body = <body>,
}
```
To be used in Tarantool `http.server` as follows:
```lua
local httpd = require('http.server').new(...)
local router = require('http.router').new(...)
httpd:set_router(router)
...
router:route( { path = '/metrics' }, prometheus.collect_http)
```

### Settings

An example:
```lua
metrics = require('metrics')
metrics.enable_default_metrics()

prometheus = require('metrics.plugins.prometheus')
httpd = require('http.server').new('0.0.0.0', 8080)
router = require('http.router').new({charset = "utf8"})
httpd:set_router(router)
router:route( { path = '/metrics' }, prometheus.collect_http)
httpd:start()
```
