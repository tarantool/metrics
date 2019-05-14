## Json

Plugin to collect metrics and encode to json string.

### API

Import json plugin:

```lua
local json_metrics = require('metrics.plugins.json')
```

#### `json.export()`
Returns:
```lua
string:
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
```
**Important** - values can be `+-math.huge`, `math.huge * 0`
Then:
`math.inf` serialized to `"inf"`
`-math.inf` serialized to `"-inf"`
`nan` serialized to `"nan"`

Example:
```lua
string:
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