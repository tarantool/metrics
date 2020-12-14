.. _metrics-reference:

===============================================================================
Metrics reference
===============================================================================

This page provides detailed description of metrics from module ``metrics``.

-------------------------------------------------------------------------------
General metrics
-------------------------------------------------------------------------------

General instance information.

* ``tnt_cfg_current_time`` - instance system time in uxix timestamp format

* ``tnt_info_uptime`` – time since instance was started, in seconds

.. _memory-general:

-------------------------------------------------------------------------------
Memory general
-------------------------------------------------------------------------------

Those metrics provide a picture of memory usage by Tarantool process.

* ``tnt_info_info_memory_cache`` - number of
  bytes in the cache for the tuples stored for the vinyl storage engine.

* ``tnt_info_info_memory_data`` - number of bytes used for storing user data (the tuples)
  with the memtx engine and with level 0 of the vinyl engine, without taking memory fragmentation into account.

* ``tnt_info_info_memory_index`` - number of bytes used for indexing user data,
  including memtx and vinyl memory tree extents, the vinyl page index, and the vinyl bloom filters.

* ``tnt_info_info_memory_lua`` - number of bytes used for Lua runtime.
  Lua memory is bounded by 2 GB per instance. Monitoring of this metric can prevent memory overflow.

* ``tnt_info_info_memory_net`` - number of bytes used for network input/output buffers.

* ``tnt_info_info_memory_tx`` - number of bytes in use by active transactions.
  For the vinyl storage engine, this is the total size of all allocated objects
  (struct txv, struct vy_tx, struct vy_read_interval) and tuples pinned for those objects.

.. _memory-allocation:

-------------------------------------------------------------------------------
Memory allocation
-------------------------------------------------------------------------------

Provides memory usage report for the slab allocator.
The slab allocator is the main allocator used to store tuples.
This can be used to monitor the total memory usage and memory fragmentation.
To learn more about use cases, see `this <https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_slab/#box-slab-info>`_

Available memory, bytes:

* ``tnt_slab_quota_size`` - the amount of memory available to store tuples and indexes, equals memtx_memory

* ``tnt_slab_arena_size`` - the total memory used for tuples and indexes together (including allocated, but currently free slabs)

* ``tnt_slab_items_size`` - the total amount of memory (including allocated, but currently free slabs) used only for tuples, no indexes

Memory usage, bytes:

* ``tnt_slab_quota_used`` - the amount of memory that is already reserved by the slab allocator

* ``tnt_slab_arena_used`` - the efficient memory used for storing tuples and indexes together (omitting allocated, but currently free slabs)

* ``tnt_slab_items_used`` - the efficient amount of memory (omitting allocated, but currently free slabs) used only for tuples, no indexes

Memory utilization, %:

* ``tnt_slab_quota_used_ratio`` - tnt_slab_quota_used / tnt_slab_quota_size

* ``tnt_slab_arena_used_ratio`` - tnt_slab_arena_used / tnt_slab_arena_used

* ``tnt_slab_items_used_ratio`` - tnt_slab_items_used / tnt_slab_items_size

.. _spaces:

-------------------------------------------------------------------------------
Spaces
-------------------------------------------------------------------------------

Those metrics provide specific information about each individual space in Tarantool instance.

* ``tnt_space_len`` - number of records in space.
  This metric always has 2 labels - ``{name="test", engine="memtx"}``. ``name`` - the name of the space,
  ``engine`` - is the engine of the space.

* ``tnt_space_bsize`` - the total number of bytes in all tuples.
  This metric always has 2 labels - ``{name="test", engine="memtx"}``. ``name`` - the name of the space,
  ``engine`` - is the engine of the space.

* ``tnt_space_index_bsize`` - the total number of bytes taken by the index.
  This metric always has 2 labels - ``{name="test", index_name="pk"}``. ``name`` - the name of the space,
  ``index_name`` - is the name of the index.

* ``tnt_space_total_bsize`` - the total size of tuples and all indexes in space.
  This metric always has 2 labels - ``{name="test", engine="memtx"}``. ``name`` - the name of the space,
  ``engine`` - is the engine of the space.

* ``tnt_space_count`` - the total tuples count for vinyl.
  This metric always has labels - ``{name="test", engine="vinyl"}``. ``name`` - the name of the space.
  ``engine`` - is the engine of the space.

.. _network:

-------------------------------------------------------------------------------
Network
-------------------------------------------------------------------------------

Network activity stats. This can be used to monitor network load, usage peaks and traffic drops.

Sent bytes:

* ``tnt_net_sent_total`` - bytes sent from this instance over network since instance start

Received bytes:

* ``tnt_net_received_total`` - bytes this instance has received since instance start

Connections:

* ``tnt_net_connections_total`` - number of incoming network connections since instance start

* ``tnt_net_connections_current`` - number of active network connections

Requests:

* ``tnt_net_requests_total`` - number of network requests this instance has handled since instance start

* ``tnt_net_requests_current`` - amount of pending network requests

.. _metrics-fibers:

-------------------------------------------------------------------------------
Fibers
-------------------------------------------------------------------------------

Provides statistics of :ref:`fibers <fiber-fibers>`. If your app creates a lot of fibers, it can be used for monitoring
fibers count and memory usage.

* ``tnt_fiber_count`` - number of fibers

* ``tnt_fiber_csw`` - averall amount of fibers context switches

* ``tnt_fiber_memalloc`` - the amount of memory that is reserved for fibers

* ``tnt_fiber_memused`` - the amount of memory that is used by fibers

.. _metrics-operations:

-------------------------------------------------------------------------------
Operations
-------------------------------------------------------------------------------

Number of iproto requests this instance has processed, aggregated by request type.
It can be used to find out which type of operation clients make more often.

* ``tnt_stats_op_total`` - total number of calls since server start

That metric have ``operation`` label to be able to distinguish different request types, e.g.:
``{operation="select"}``

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

.. _metrics-replication:

-------------------------------------------------------------------------------
Replication
-------------------------------------------------------------------------------

Provides information of current replication status. To learn more about replication
mechanism in Tarantool, see :ref:`this <replication-mechanism>`

* ``tnt_info_lsn`` – LSN of instance

* ``tnt_info_vclock`` – LSN number in vclock. This metric always has label - ``{id="id"}``,
  where ``id`` is instance number in replicaset

* ``tnt_replication_replica_<id>_lsn`` / ``tnt_replication_master_<id>_lsn`` - LSN of master/replica,
  ``id`` is instance number in replicaset

* ``tnt_replication_<id>_lag`` - replication lag value in seconds, ``id`` is instance number in replicaset

.. _metrics-runtime:

-------------------------------------------------------------------------------
Runtime
-------------------------------------------------------------------------------

* ``tnt_runtime_lua`` – Lua garbage collector size in bytes

* ``tnt_runtime_used`` - number of bytes used for Lua runtime

.. _metrics-cartridge:

-------------------------------------------------------------------------------
Cartridge
-------------------------------------------------------------------------------

* ``cartridge_issues`` - Number of
  `issues <https://www.tarantool.io/en/doc/latest/book/cartridge/cartridge_api/modules/cartridge.issues/>`
  across cluster instances. This metric always has labels - ``{level="critical"}``.
  ``level`` - the level of the issue. ``critical`` level is memory used ratio > 90%,
  ``warning`` level is memory used ratio > 60% or replication issues on cluster.

.. _metrics-luajit:

-------------------------------------------------------------------------------
LuaJIT metrics
-------------------------------------------------------------------------------

LuaJIT metrics helps to understand Lua GC state.

* ``lj_gc_freed``  - total amount of freed memory

* ``lj_strhash_hit`` - number of strings being interned

* ``lj_gc_steps_atomic`` - count of incremental GC steps (atomic state)

* ``lj_strhash_miss`` - total number of strings allocations during the platform lifetime

* ``lj_gc_steps_sweepstring`` - count of incremental GC steps (sweepstring state)

* ``lj_gc_strnum`` - amount of allocated ``string`` objects

* ``lj_gc_tabnum`` - amount of allocated ``table`` objects

* ``lj_gc_cdatanum`` - amount of allocated ``cdata`` objects

* ``lj_jit_snap_restore`` - overall number of snap restores

* ``lj_gc_total`` - memory currently allocated

* ``lj_gc_udatanum`` - amount of allocated ``udata`` objects

* ``lj_gc_steps_finalize`` - count of incremental GC steps (finalize state)

* ``lj_gc_allocated`` - total amount of allocated memory

* ``lj_jit_trace_num`` - amount of JIT traces

* ``lj_gc_steps_sweep`` - count of incremental GC steps (sweep state)

* ``lj_jit_trace_abort`` - overall number of abort traces

* ``lj_jit_mcode_size`` - total size of all allocated machine code areas

* ``lj_gc_steps_propagate`` - count of incremental GC steps (propagate state)

* ``lj_gc_steps_pause`` - count of incremental GC steps (pause state)

.. _metrics-psutils:

-------------------------------------------------------------------------------
CPU metrics
-------------------------------------------------------------------------------

Those metrics provides CPU usage statistics. Only for Linux.

* ``tnt_cpu_count`` - the number of processors

* ``tnt_cpu_thread`` - Tarantool thread cpu time. This metric always has labels -
  ``{kind="user", thread_name="tarantool", thread_pid="pid", file_name="init.lua"}``,
  where ``kind`` is ``user`` or ``system``, ``thread_name`` is ``tarantool`` or
  ``coio``, ``file_name`` is entrypoint file name, e.g. ``init.lua``.
