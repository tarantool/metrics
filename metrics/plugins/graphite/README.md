## Graphite

Plugin to collect metrics and send them to graphite server.

### API

Import graphite plugin module:

```lua
local graphite = require('metrics.plugins.graphite')
```

To start automatically exporting current values of all `metrics.{counter,gauge,histogram}` just call:

#### `graphite.init(options)`

`options` is a Lua table:
- `prefix` (string) - metrics prefix (default is `'tarantool'`);
- `host` (string) - graphite server host (default is `'127.0.0.1'`);
- `port` (number) - graphite server port (default is `2003`);
- `send_interval` (number) - metrics collect interval in seconds (default is `2`);

This creates a background fiber, that periodically sends all metrics to remote Graphite server.

Exported metric name is sent in format `<prefix>.<metric_name>`.
