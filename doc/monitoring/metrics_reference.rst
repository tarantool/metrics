.. _metrics-metrics-reference:

===============================================================================
Metrics reference
===============================================================================

This page provides detailed description of each Tarantool metrics.

-------------------------------------------------------------------------------
Network general
-------------------------------------------------------------------------------

Network activity stats.

``tnt_net_sent_total`` - bytes sent from this instance over network since instance start

``tnt_net_received_total`` - bytes this instance received since instance start

``tnt_net_connections_total`` - number of incoming network connections since instance start

``tnt_net_connections_current`` - number of active network connections

``tnt_net_requests_total`` - nubmer of network requests this instance have handled since instance start

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
