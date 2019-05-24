## Plain

Plugin to collect metrics and encode to json string.

### API

Import json plugin:

```lua
local json_metrics = require('metrics.plugins.plain')
```

#### `json.export()`
Returns:
```lua
string:
{
    "<name_obs>{<key>=\"value\"}":{
        "timestamp":<number>,
        "value":<value>
    }
}
```
**Important** - values can be **+-math.huge**, **math.huge * 0**
In such cases, the value will be represented by the string, in other cases the number.

Example:
```lua
string:
{
    "name{label=\"-math.huge\"}":{
        "timestamp":1558699055876857,
        "value":"-inf"
    },
    "name{label=\"math.huge\"}":{
        "timestamp":1558699055876857,
        "value":"inf"
    },
    "name{label=\"math.huge * 0\"}":{
        "timestamp":1558699055876857,
        "value":"nan"
    },
    "name{label=\"number\"}":{
        "timestamp":1558700701857282,
        "value":0.333
    }
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
            text = json_exporter.export()
        })
    end
)
```
