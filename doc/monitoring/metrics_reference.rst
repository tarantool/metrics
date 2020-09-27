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

Number of iproto requests this instance have processed, aggregated by request type. 
E.g. requests made from Java client.

Two types of metrics provided for each request type:

* ``tnt_stats_op_total`` - total number of calls since server start
* ``tnt_stats_op_rps`` - number of calls for the last 5 seconds

Each metric have ``operation`` label to be able to distinguish different request types, e.g.:

.. code-block:: none

    tnt_stat_op_total{operation="select"} 10

which means that there were 10 ``select`` calls since server start.

Request type could be one of:

- ``delete`` - delete calls
- ``error`` - requests resulted in an error
- ``update`` - update calls
- ``call`` - requests to execute stored procedures
- ``auth`` - authentication requests
- ``eval`` - calls to evaluate lua code
- ``replace`` - replace call
- ``execute`` - execute SQL calls
- ``select`` - select calls
- ``upsert`` - upsert calls
- ``prepare`` - SQL prepare calls 
- ``insert`` - insert calls

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
