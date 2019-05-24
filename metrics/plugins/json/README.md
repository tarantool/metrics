## Plain

Plugin to collect metrics to simple table.

### API

Import plain plugin:

```lua
local plain_metrics = require('metrics.plugins.plain')
```

#### `plain.collect()`
Returns:
```lua
{
    metric_name = {
        timestamp = 1558087314351497,
        label_pairs = []
        value = '2.18'
    },
}
```
To be used in Tarantool `http.server` as follows:
```lua
local httpd = require('http.server').new(...)
...
httpd:route({
        method = 'GET',
        path = '/metrics',
        public = true,
    },
    function(req)
        return req:render({
            json = plain_metrics.collect()
        })
    end
)
```
