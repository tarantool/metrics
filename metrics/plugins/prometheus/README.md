## Prometheus

This is a Lua library that makes it easy to collect metrics from your
Tarantool apps and databases and expose them via the Prometheus protocol.

### Usage

Import the Prometheus plugin:
```lua
local prometheus = require('metrics.plugins.prometheus')
```

Further, use the `prometheus.collect_http()` function, which returns:
```lua
{
    status = 200,
    headers = <headers>,
    body = <body>,
}
```

See the [Prometheus exposition format](https://github.com/prometheus/docs/blob/master/content/docs/instrumenting/exposition_formats.md)
for details on `<body>` and `<headers>`.

Use in Tarantool [http.server](https://github.com/tarantool/http/) as follows:

* in Tarantool [http.server v1](https://github.com/tarantool/http/tree/tarantool-1.6)
  (currently used in [Tarantool Cartridge](https://github.com/tarantool/cartridge)):
  ```lua
    local httpd = require('http.server').new(...)
    ...
    httpd:route( { path = '/metrics' }, prometheus.collect_http)
  ```

* in Tarantool [http.server v2](https://github.com/tarantool/http/)
  (the latest version):
  ```lua
    local httpd = require('http.server').new(...)
    local router = require('http.router').new(...)
    httpd:set_router(router)
    ...
    router:route( { path = '/metrics' }, prometheus.collect_http)
  ```

### Sample settings

* for Tarantool `http.server` v1:
  ```lua
    metrics = require('metrics')
    metrics.enable_default_metrics()

    prometheus = require('metrics.plugins.prometheus')
    httpd = require('http.server').new('0.0.0.0', 8080)
    httpd:route( { path = '/metrics' }, prometheus.collect_http)
    httpd:start()
  ```

* for Tarantool Cartridge (with `http.server` v1):
  ```lua
    cartridge = require('cartridge')
    httpd = cartridge.service_get('httpd')
    metrics = require('metrics')
    metrics.enable_default_metrics()
    prometheus = require('metrics.plugins.prometheus')
    httpd:route( { path = '/metrics' }, prometheus.collect_http)
  ```

* for Tarantool `http.server` v2:
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
