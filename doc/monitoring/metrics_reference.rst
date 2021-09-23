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

* ``tnt_read_only``—is instance in read only mode (value is 1 if true and 0 if false).

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

``tnt_cartridge_issues``—number of
:ref:`issues of instance <cartridge.issues>`.
This metric always has label ``{level="critical"}``, where
``level`` is the level of the issue:

*   ``critical`` level is associated with critical
    instance problems, for example when memory used ratio is more than 90%.
*   ``warning`` level is associated with
    other cluster problems, e.g. replication issues on instance.


``tnt_clock_delta``—the clock drift across the cluster.
This metric always has the label ``{delta="..."}``, which is one of:

*   ``max``—the difference with the fastest clock (always positive),
*   ``min``—the difference with the slowest clock (always negative).
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

Vinyl metrics provide the :ref:`vinyl engine <engines-vinyl>` statistics.

**Disk**

The disk metrics are used to monitor the overall data size on disk.

*   ``tnt_vinyl_disk_data_size``—the amount of data stored in the ``.run`` files
    located in the :ref:`vinyl_dir <cfg_basic-vinyl_dir>` directory, bytes.

*   ``tnt_vinyl_disk_index_size``—the amount of data stored in the ``.index`` files
    located in the :ref:`vinyl_dir <cfg_basic-vinyl_dir>` directory, bytes.

.. _metrics-vinyl-regulator:

**Regulator**

The vinyl regulator decides when to take the disk IO actions.
It groups activities in batches so that they will be more consistent and
efficient.

*   ``tnt_vinyl_regulator_dump_bandwidth``—the estimated average rate of taking
    dumps, bytes per second. Initially, the rate value is 10485760
    (10 megabytes per second) and being recalculated depending on the the actual
    rate. Only significant dumps that are larger than one megabyte are used for
    the estimate.

*   ``tnt_vinyl_regulator_write_rate``—the actual average rate of performing the
    write operations, bytes per second. The rate is calculated as
    a 5-second moving average. If the metric value is gradually going down,
    this can indicate some disk issues.

*   ``tnt_vinyl_regulator_rate_limit``—the write rate limit, bytes per second.
    The regulator imposes the limit on transactions based on the observed
    dump/compaction performance. If the metric value is down to approximately
    10^5, this indicates issues with the disk or the :ref:`scheduler <metrics-vinyl-scheduler>`.

*   ``tnt_vinyl_regulator_dump_watermark``—the maximum amount of memory used
    for in-memory storing of a vinyl LSM tree, bytes. When accessing this
    maximum, the dumping must occur. For details, see :ref:`engines-algorithm_filling_lsm`.
    The value is slightly smaller than the amount of memory allocated
    for vinyl trees, which is the :ref:`vinyl_memory <cfg_storage-vinyl_memory>`
    parameter.

**Transactional activity**

*   ``tnt_vinyl_tx_commit``—the counter of commits (successful transaction ends).
    It includes implicit commits: for example, any insert operation causes a
    commit unless it is within a
    :doc:`/reference/reference_lua/box_txn_management/begin`–:doc:`/reference/reference_lua/box_txn_management/commit`
    block.

*   ``tnt_vinyl_tx_rollback``—the counter of rollbacks (unsuccessful transaction
    ends). This is not merely a count of explicit :doc:`/reference/reference_lua/box_txn_management/rollback`
    requests—it includes requests that ended with errors.

*   ``tnt_vinyl_tx_conflict``—the counter of conflicts that caused transactions
    to roll back. The ratio ``tnt_vinyl_tx_conflict / tnt_vinyl_tx_commit``
    above 5% indicates that vinyl is not healthy. At this moment you'll probably
    see a lot of other problems with vinyl.

*   ``tnt_vinyl_tx_read_views``—the current number of read views, that is, transactions
    entered a read-only state to avoid conflict temporarily. Usually the value
    is ``0``. If it stays non-zero for a long time, it indicates of a memory leak.

**Memory**

These metrics show the state memory areas used by vinyl for caches and write
buffers.

*   ``tnt_vinyl_memory_tuple_cache``—the amount of memory that is being used
    for storing tuples (data), bytes.

*   ``tnt_vinyl_memory_level0``—the "level 0" (L0) memory area, bytes.
    L0 is the area that vinyl can use for in-memory storage of an LSM tree.
    By monitoring the metric, you can see when L0 is getting close to its
    maximum (``tnt_vinyl_regulator_dump_watermark``) at which a dump will be
    taken. You can expect L0 = 0 immediately after the dump operation is
    completed.

*   ``tnt_vinyl_memory_page_index``—the amount of memory that is being used
    for storing indexes, bytes. If the metric value is close to :ref:`vinyl_memory <cfg_storage-vinyl_memory>`,
    this indicates the incorrectly chosen :ref:`vinyl_page_size <cfg_storage-vinyl_page_size>`.

*   ``tnt_vinyl_memory_bloom_filter``—the amount of memory used by
    :ref:`bloom filters <vinyl-lsm_disadvantages_compression_bloom_filters>`,
    bytes.

.. _metrics-vinyl-scheduler:

**Scheduler**

The vinyl scheduler invokes the :ref:`regulator <metrics-vinyl-regulator>` and
updates the related variables. This happens once per second.

*   ``tnt_vinyl_scheduler_tasks``—the number of the scheduler dump/compaction
    tasks. The metric always has label ``{status = <status_value>}``
    where ``<status_value>`` can be:

    *   ``inprogress`` for currently running tasks
    *   ``completed`` for successfully completed tasks
    *   ``failed`` for tasks aborted due to errors.

*   ``tnt_vinyl_scheduler_dump_time``—total time spent by all worker threads
    performing dumps, seconds.

*   ``tnt_vinyl_scheduler_dump_count``—the counter of dumps completed.
