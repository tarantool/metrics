.. _metrics-reference:

===============================================================================
Metrics reference
===============================================================================

This page provides a detailed description of metrics from the ``metrics`` module.

-------------------------------------------------------------------------------
General metrics
-------------------------------------------------------------------------------

General instance information:

* ``tnt_cfg_current_time``—instance system time in the Unix timestamp format.

* ``tnt_info_uptime``—time in seconds since instance has started.

.. _memory-general:

-------------------------------------------------------------------------------
Memory general
-------------------------------------------------------------------------------

These metrics provide a picture of memory usage by the Tarantool process.

* ``tnt_info_memory_cache``—number of
  bytes in the cache for the tuples stored for the vinyl storage engine.

* ``tnt_info_memory_data``—number of bytes used for storing user data (the tuples)
  with the memtx engine and with level 0 of the vinyl engine, without taking memory fragmentation into account.

* ``tnt_info_memory_index``—number of bytes used for indexing user data,
  including memtx and vinyl memory tree extents, the vinyl page index, and the vinyl bloom filters.

* ``tnt_info_memory_lua``—number of bytes used for the Lua runtime.
  Lua memory is bounded by 2 GB per instance. Monitoring this metric can prevent memory overflow.

* ``tnt_info_memory_net``—number of bytes used for network input/output buffers.

* ``tnt_info_memory_tx``—number of bytes in use by active transactions.
  For the vinyl storage engine, this is the total size of all allocated objects
  (struct ``txv``, struct ``vy_tx``, struct ``vy_read_interval``) and tuples pinned for those objects.

.. _memory-allocation:

-------------------------------------------------------------------------------
Memory allocation
-------------------------------------------------------------------------------

Provides a memory usage report for the slab allocator.
The slab allocator is the main allocator used to store tuples.
This can be used to monitor the total memory usage and memory fragmentation.
To learn more about use cases, refer to the
:ref:`documentation for box.slab submodule <box_introspection-box_slab>`.

Available memory, bytes:

* ``tnt_slab_quota_size``—the amount of memory available to store tuples and indexes, equals ``memtx_memory``.

* ``tnt_slab_arena_size``—the total memory used for tuples and indexes together (including allocated, but currently free slabs).

* ``tnt_slab_items_size``—the total amount of memory (including allocated, but currently free slabs) used only for tuples, no indexes.

Memory usage, bytes:

* ``tnt_slab_quota_used``—the amount of memory that is already reserved by the slab allocator.

* ``tnt_slab_arena_used``—the efficient memory used for storing tuples and indexes together (omitting allocated, but currently free slabs).

* ``tnt_slab_items_used``—the efficient amount of memory (omitting allocated, but currently free slabs) used only for tuples, no indexes.

Memory utilization, %:

* ``tnt_slab_quota_used_ratio``—tnt_slab_quota_used / tnt_slab_quota_size.

* ``tnt_slab_arena_used_ratio``—tnt_slab_arena_used / tnt_slab_arena_used.

* ``tnt_slab_items_used_ratio``—tnt_slab_items_used / tnt_slab_items_size.

.. _spaces:

-------------------------------------------------------------------------------
Spaces
-------------------------------------------------------------------------------

These metrics provide specific information about each individual space in a Tarantool instance:

* ``tnt_space_len``—number of records in the space.
  This metric always has 2 labels: ``{name="test", engine="memtx"}``,
  where ``name`` is the name of the space, and
  ``engine`` is the engine of the space.

* ``tnt_space_bsize``—the total number of bytes in all tuples.
  This metric always has 2 labels: ``{name="test", engine="memtx"}``,
  where ``name`` is the name of the space, and
  ``engine`` is the engine of the space.

* ``tnt_space_index_bsize``—the total number of bytes taken by the index.
  This metric always has 2 labels: ``{name="test", index_name="pk"}``,
  where ``name`` is the name of the space, and
  ``index_name`` is the name of the index.

* ``tnt_space_total_bsize``—the total size of tuples and all indexes in space.
  This metric always has 2 labels: ``{name="test", engine="memtx"}``,
  where ``name`` is the name of the space, and
  ``engine`` is the engine of the space.

* ``tnt_space_count``—the total tuples count for vinyl.
  This metric always has labels—``{name="test", engine="vinyl"}``,
  where ``name`` is the name of the space, and
  ``engine`` is the engine of the space.

.. _network:

-------------------------------------------------------------------------------
Network
-------------------------------------------------------------------------------

Network activity stats. This can be used to monitor network load, usage peaks and traffic drops.

Sent bytes:

* ``tnt_net_sent_total``—bytes sent from this instance over network since instance start time.

Received bytes:

* ``tnt_net_received_total``—bytes this instance has received since instance start time.

Connections:

* ``tnt_net_connections_total``—number of incoming network connections since instance start time.

* ``tnt_net_connections_current``—number of active network connections.

Requests:

* ``tnt_net_requests_total``—number of network requests this instance has handled since instance start time.

* ``tnt_net_requests_current``—amount of pending network requests.

.. _metrics-fibers:

-------------------------------------------------------------------------------
Fibers
-------------------------------------------------------------------------------

Provides the statistics of :ref:`fibers <fiber-fibers>`. If your app creates a lot of fibers, it can be used for monitoring
fibers count and memory usage:

* ``tnt_fiber_count``—number of fibers.

* ``tnt_fiber_csw``—overall amount of fibers context switches.

* ``tnt_fiber_memalloc``—the amount of memory that is reserved for fibers.

* ``tnt_fiber_memused``—the amount of memory that is used by fibers.

.. _metrics-operations:

-------------------------------------------------------------------------------
Operations
-------------------------------------------------------------------------------

Number of iproto requests this instance has processed, aggregated by request type.
It can be used to find out which type of operation clients make more often.

* ``tnt_stats_op_total``—total number of calls since server start

That metric have ``operation`` label to be able to distinguish different request types, e.g.:
``{operation="select"}``

Request type could be one of:

- ``delete``—delete calls
- ``error``—requests resulted in an error
- ``update``—update calls
- ``call``—requests to execute stored procedures
- ``auth``—authentication requests
- ``eval``—calls to evaluate lua code
- ``replace``—replace call
- ``execute``—execute SQL calls
- ``select``—select calls
- ``upsert``—upsert calls
- ``prepare``—SQL prepare calls
- ``insert``—insert calls

.. _metrics-replication:

-------------------------------------------------------------------------------
Replication
-------------------------------------------------------------------------------

Provides information of current replication status. To learn more about replication
mechanism in Tarantool, see :ref:`this <replication-mechanism>`.

* ``tnt_info_lsn``—LSN of the instance.

* ``tnt_info_vclock``—LSN number in vclock. This metric always has label ``{id="id"}``,
  where ``id`` is the instance's number in the replicaset.

* ``tnt_replication_replica_<id>_lsn`` / ``tnt_replication_master_<id>_lsn``—LSN of master/replica, where
  ``id`` is the instance's number in the replicaset.

* ``tnt_replication_<id>_lag``—replication lag value in seconds, where
  ``id`` is the instance's number in the replicaset.

.. _metrics-runtime:

-------------------------------------------------------------------------------
Runtime
-------------------------------------------------------------------------------

* ``tnt_runtime_lua``—Lua garbage collector size in bytes.

* ``tnt_runtime_used``—number of bytes used for the Lua runtime.

.. _metrics-cartridge:

-------------------------------------------------------------------------------
Cartridge
-------------------------------------------------------------------------------

``cartridge_issues``—Number of
:ref:`issues across cluster instances <cartridge.issues>`.
This metric always has label ``{level="critical"}``, where
``level`` is the level of the issue:

*   ``critical`` level is associated with critical
    cluster problems, for example when memory used ratio is more than 90%.
*   ``warning`` level is associated with
    other cluster problems, e.g. replication issues on cluster.

.. _metrics-luajit:

-------------------------------------------------------------------------------
LuaJIT metrics
-------------------------------------------------------------------------------

LuaJIT metrics help understand the stage of Lua garbage collector.
They are available in Tarantool 2.6 and later.

General JIT metrics:

* ``lj_jit_snap_restore``—overall number of snap restores.

* ``lj_jit_trace_num``—number of JIT traces.

* ``lj_jit_trace_abort``—overall number of abort traces.

* ``lj_jit_mcode_size``—total size of all allocated machine code areas.

JIT strings:

* ``lj_strhash_hit``—number of strings being interned.

* ``lj_strhash_miss``—total number of string allocations.

GC steps:

* ``lj_gc_steps_atomic``—count of incremental GC steps (atomic state).

* ``lj_gc_steps_sweepstring``—count of incremental GC steps (sweepstring state).

* ``lj_gc_steps_finalize``—count of incremental GC steps (finalize state).

* ``lj_gc_steps_sweep``—count of incremental GC steps (sweep state).

* ``lj_gc_steps_propagate``—count of incremental GC steps (propagate state).

* ``lj_gc_steps_pause``—count of incremental GC steps (pause state).

Allocations:

* ``lj_gc_strnum``—number of allocated ``string`` objects.

* ``lj_gc_tabnum``—number of allocated ``table`` objects.

* ``lj_gc_cdatanum``—number of allocated ``cdata`` objects.

* ``lj_gc_udatanum``—number of allocated ``udata`` objects.

* ``lj_gc_freed`` —total amount of freed memory.

* ``lj_gc_total``—current allocated Lua memory.

* ``lj_gc_allocated``—total amount of allocated memory.

.. _metrics-psutils:

-------------------------------------------------------------------------------
CPU metrics
-------------------------------------------------------------------------------

These metrics provide the CPU usage statistics.
They are only available on Linux.

* ``tnt_cpu_count``—total number of processors configured by the operating system.

* ``tnt_cpu_total``—host CPU time.

* ``tnt_cpu_thread``—Tarantool thread CPU time. This metric always has labels
  ``{kind="user", thread_name="tarantool", thread_pid="pid", file_name="init.lua"}``,
  where:

    *   ``kind`` can be either ``user`` or ``system``.
    *   ``thread_name`` is ``tarantool``, ``wal``, ``iproto``, or ``coio``.
    *   ``file_name`` is the entrypoint file name, for example, ``init.lua``.

There are also the following cross-platform metrics obtained using the call ``getrusage()``

* ``tnt_cpu_user_time`` - Tarantool CPU user time.
* ``tnt_cpu_system_time`` - Tarantool CPU system time.

.. _metrics-vinyl:

-------------------------------------------------------------------------------
Vinyl
-------------------------------------------------------------------------------

Vinyl metrics provide :ref:`vinyl engine <storing-data-with-vinyl>` statistics.

**Disk**

* ``tnt_vinyl_disk_data_size`` - the amount of data that has gone into files, in bytes

* ``tnt_vinyl_disk_index_size`` - the amount of index that has gone into files, in bytes

* ``tnt_vinyl_disk_data_compacted_size`` - sum size of data stored at the last LSM tree level,
in bytes, without taking disk compression into account

**Regulator**

* ``tnt_vinyl_regulator_dump_bandwidth`` - the estimated average rate at which dumps are done.
Initially this will appear as 10485760 (10 megabytes per second). Only significant dumps
(larger than one megabyte) are used for estimating

* ``tnt_vinyl_regulator_write_rate`` - the actual average rate at which recent writes to disk are done.
Averaging is done over a 5-second time window

* ``tnt_vinyl_regulator_rate_limit`` - the write rate limit, in bytes per second,
imposed on transactions by the regulator based on the observed dump/compaction performance

* ``tnt_vinyl_regulator_dump_watermark`` - the point when dumping must occur.
The value is slightly smaller than the amount of memory that is allocated for vinyl trees,
which is the vinyl_memory paramete

**Transactional activity**

* ``tnt_vinyl_tx_conflict`` - counts conflicts that caused a transaction to roll back

* ``tnt_vinyl_tx_commit`` - the count of commits (successful transaction ends).
It includes implicit commits, for example any insert causes a commit unless it is within a begin-end block

* ``tnt_vinyl_tx_rollback`` - the count of rollbacks (unsuccessful transaction ends).
This is not merely a count of explicit ``box.rollback()`` requests – it includes requests that ended in errors

**Memory**

* ``tnt_vinyl_memory_tuple_cache`` - the number of bytes that are being used for tuples

* ``tnt_vinyl_memory_level0`` - is the “level0” memory area, sometimes abbreviated “L0”,
which is the area that vinyl can use for in-memory storage of an LSM tree.
Therefore we can say that “L0 is becoming full” when the amount in this metric is close to the maximum,
which is ``tnt_vinyl_regulator_dump_watermark``. We can expect that “L0 = 0” immediately after a dump

* ``tnt_vinyl_memory_page_index`` - the number of bytes that are being used for indexes

* ``tnt_vinyl_memory_bloom_filter`` - the number of bytes that are being used for bloom filter

**Scheduler**

* ``tnt_vinyl_scheduler_tasks_inprogress`` - number of currently running dump/compaction tasks

* ``tnt_vinyl_scheduler_tasks_completed`` - number of successfully completed dump/compaction tasks

* ``tnt_vinyl_scheduler_tasks_failed`` - number of dump/compaction tasks aborted due to errors

* ``tnt_vinyl_scheduler_dump_time`` - total time spent by all worker threads performing dumps, in seconds

* ``tnt_vinyl_scheduler_dump_count`` - the count of completed dumps
