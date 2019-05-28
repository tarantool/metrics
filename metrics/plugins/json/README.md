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
        "label_name_1":<label_value_1>,
        ...
        "label_name_n":<label_value_n>,
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
        "timestamp":1559036539723610,
        "type":"nan",
        "name":"test_nan",
        "value":"nan"
    },
    {
        "timestamp":1559036539723610,
        "type":"-inf",
        "name":"test_inf",
        "value":"-inf"
    },
    {
        "timestamp":1559036539723610,
        "type":"inf",
        "name":"test_inf",
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