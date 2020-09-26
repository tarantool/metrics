.. _metrics-metrics-reference:

===============================================================================
Metrics reference
===============================================================================

This page provides detailed description of each Tarantool metrics.

-------------------------------------------------------------------------------
Network general
-------------------------------------------------------------------------------

# HELP tnt_net_sent_total Totally sent in bytes (incremental counter from server start)
# TYPE tnt_net_sent_total gauge
tnt_net_sent_total 182862

# HELP tnt_net_sent_rps Sending RPS (last 5 seconds)
# TYPE tnt_net_sent_rps gauge
tnt_net_sent_rps 640

# HELP tnt_net_received_total Totally received in bytes (counter from server start)
# TYPE tnt_net_received_total gauge
tnt_net_received_total 4613

# HELP tnt_net_received_rps Receive RPS
# TYPE tnt_net_received_rps gauge
tnt_net_received_rps 21

# HELP tnt_net_connections_rps Connection RPS
# TYPE tnt_net_connections_rps gauge
tnt_net_connections_rps 0

# HELP tnt_net_connections_total Connections total amount
# TYPE tnt_net_connections_total gauge
tnt_net_connections_total 4

# HELP tnt_net_connections_current Current connections amount
# TYPE tnt_net_connections_current gauge
tnt_net_connections_current 3

# HELP tnt_net_requests_rps Requests RPS (last 5 seconds)
# TYPE tnt_net_requests_rps gauge
tnt_net_requests_rps 0

# HELP tnt_net_requests_total Requests total amount
# TYPE tnt_net_requests_total gauge
tnt_net_requests_total 201

# HELP tnt_net_requests_current Pending requests
# TYPE tnt_net_requests_current gauge
tnt_net_requests_current 0

-------------------------------------------------------------------------------
Operations
-------------------------------------------------------------------------------
# HELP tnt_stats_op_total Total amount of operations
# TYPE tnt_stats_op_total gauge
tnt_stats_op_total{operation="call"} 0

# HELP tnt_stats_op_rps Total RPS
# TYPE tnt_stats_op_rps gauge
tnt_stats_op_rps{operation="call"} 0

Operations:
delete
error
update
call
auth
eval
replace
execute
select
upsert
prepare
insert

-------------------------------------------------------------------------------
Replication
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
Memory general
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
Memory data
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
Memory Lua
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
Spaces
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
Fibers
-------------------------------------------------------------------------------
