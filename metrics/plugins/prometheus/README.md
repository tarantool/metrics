## Prometheus

Plugin to collect metrics and send them to Prometheus server.

### API

Import Prometheus Plugin:

```lua
local prometheus = require('metrics.plugins.prometheus')
```

#### `prometheus.collect_http()`
Returns:
```lua
{
    status = <http-status>,
    headers = <headers>,
    body = <body>,
}
```
To be used in Tarantool `http.server` as follows:
```lua
local httpd = require('http.server').new(...)
...
httpd:route( { path = '/metrics' }, prometheus.collect_http)
```
