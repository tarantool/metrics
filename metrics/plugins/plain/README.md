## Plain metrics

Plugin to collect metrics to simple table.

### API

Import Plain metrics plugin:

```lua
local plain_metrics = require('metrics.plugins.plain_metrics')
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
...
httpd:route( { path = '/metrics' }, prometheus.collect_http)
```
