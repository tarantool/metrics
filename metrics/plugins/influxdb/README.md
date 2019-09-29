## InfluxDB

Plugin to collect metrics and send them to InfluxDB server.

### API

Import InfluxDB plugin module:

```lua
local influxdb_exporter = require('metrics.plugins.influxdb')
```

To start automatically exporting current values of all `metrics.{counter,gauge,histogram}` just call:

#### `influxdb_exporter.init(options)`

`options` is a Lua table:
- `host` (string) - graphite server host (default is `'127.0.0.1'`);
- `port` (number) - graphite server port (default is `8086`);
- `db_name` (string) - metrics database (default is `'tarantool'`);
- `send_interval` (number) - metrics collect interval in seconds (default is `2`);
- `field_name` (string) - name of value field key (default is `value`);
- `username` (string) - influxDB username (default is empty, no authorisation is used);
- `password` (string) - influxDB password (default is empty, no authorisation is used);

This creates a background fiber, that periodically sends all metrics to remote InfluxDB server.
