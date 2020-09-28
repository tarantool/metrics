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
Memory allocation
-------------------------------------------------------------------------------

Provides memory usage report for the slab allocator. 
The slab allocator is the main allocator used to store tuples. 
This can be used to monitor the total memory usage and memory fragmentation.

Available memory, bytes:

``tnt_slab_quota_size`` - the amount of memory available to store tuples and indexes, equals memtx_memory

``tnt_slab_arena_size`` - the total memory used for tuples and indexes together

``tnt_slab_items_size`` - is the total amount of memory used only for tuples, no indexes

Memory usage, bytes:

``tnt_slab_quota_used`` - is the amount of memory that is already distributed to the slab allocator

``tnt_slab_arena_used`` - is the efficient memory used for storing tuples and indexes together (omitting allocated, but currently free slabs)

``tnt_slab_items_used`` - is the efficient amount of memory (omitting allocated, but currently free slabs) used only for tuples, no indexes

Memory utilization, %:

``tnt_slab_quota_used_ratio`` - tnt_slab_quota_used / tnt_slab_quota_size

``tnt_slab_arena_used_ratio`` - tnt_slab_arena_used / tnt_slab_arena_used

``tnt_slab_items_used_ratio`` - tnt_slab_items_used / tnt_slab_items_size

-------------------------------------------------------------------------------
Memory Lua
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
Spaces
-------------------------------------------------------------------------------

``tnt_space_len`` - number of records in space. 
Thi metric always have 2 labels - ``{name="test", engine="memtx"}``. ``name`` - the name of the space,
``engine`` - is the engine of the space.

``tnt_space_bsize`` - the total number of bytes in all tuples. 
This metric always have 2 labels - ``{name="test", engine="memtx"}``. ``name`` - the name of the space,
``engine`` - is the engine of the space.

``tnt_space_index_bsize`` - the total number of bytes taken by the index. 
This metric always have 2 labels - ``{name="test", index_name="pk"}``. ``name`` - the name of the space,
``index_name`` - is the name of the index.

``tnt_space_total_bsize`` - the total size of tuples and all indexes in space. 
This metric always have 2 labels - ``{name="test", engine="memtx"}``. ``name`` - the name of the space,
``engine`` - is the engine of the space.

-------------------------------------------------------------------------------
Fibers
-------------------------------------------------------------------------------
