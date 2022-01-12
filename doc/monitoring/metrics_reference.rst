..  _metrics-reference:

Metrics reference
=================

This page provides a detailed description of metrics from the ``metrics`` module.

General metrics
---------------

General instance information:

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_cfg_current_time``
            -   Instance system time in the Unix timestamp format
        *   -   ``tnt_info_uptime``
            -   Time in seconds since the instance has started
        *   -   ``tnt_read_only``
            -   Indicates if the instance is in read-only mode (``1`` if true, ``0`` if false)

..  _metrics-reference-memory_general:

Memory general
--------------

The following metrics provide a picture of memory usage by the Tarantool process.

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_info_memory_cache``
            -   Number of bytes in the cache used to store
                tuples with the vinyl storage engine.
        *   -   ``tnt_info_memory_data``
            -   Number of bytes used to store user data (tuples)
                with the memtx engine and with level 0 of the vinyl engine,
                without regard for memory fragmentation.
        *   -   ``tnt_info_memory_index``
            -   Number of bytes used for indexing user data.
                Includes memtx and vinyl memory tree extents,
                the vinyl page index, and the vinyl bloom filters.
        *   -   ``tnt_info_memory_lua``
            -   Number of bytes used for the Lua runtime.
                The Lua memory is limited to 2 GB per instance.
                Monitoring this metric can prevent memory overflow.
        *   -   ``tnt_info_memory_net``
            -   Number of bytes used for network input/output buffers.
        *   -   ``tnt_info_memory_tx``
            -   Number of bytes in use by active transactions.
                For the vinyl storage engine,
                this is the total size of all allocated objects
                (struct ``txv``, struct ``vy_tx``, struct ``vy_read_interval``)
                and tuples pinned for those objects.

..  _metrics-reference-memory_allocation:

Memory allocation
-----------------

Provides a memory usage report for the slab allocator.
The slab allocator is the main allocator used to store tuples.
The following metrics help monitor the total memory usage and memory fragmentation.
To learn more about use cases, refer to the
:ref:`box.slab submodule documentation <box_introspection-box_slab>`.

Available memory, bytes:

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_slab_quota_size``
            -   Amount of memory available to store tuples and indexes.
                Is equal to ``memtx_memory``.
        *   -   ``tnt_slab_arena_size``
            -   Total memory available to store both tuples and indexes.
                Includes allocated but currently free slabs.
        *   -   ``tnt_slab_items_size``
            -   Total amount of memory available to store only tuples and not indexes.
                Includes allocated but currently free slabs.

Memory usage, bytes:

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_slab_quota_used``
            -   The amount of memory that is already reserved by the slab allocator.
        *   -   ``tnt_slab_arena_used``
            -   The effective memory used to store both tuples and indexes.
                Disregards allocated but currently free slabs.
        *   -   ``tnt_slab_items_used``
            -   The effective memory used to store only tuples and not indexes.
                Disregards allocated but currently free slabs.

Memory utilization, %:

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_slab_quota_used_ratio``
            -   ``tnt_slab_quota_used / tnt_slab_quota_size``
        *   -   ``tnt_slab_arena_used_ratio``
            -   ``tnt_slab_arena_used / tnt_slab_arena_size``
        *   -   ``tnt_slab_items_used_ratio``
            -   ``tnt_slab_items_used / tnt_slab_items_size``

..  _metrics-reference-spaces:

Spaces
------

The following metrics provide specific information
about each individual space in a Tarantool instance.

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_space_len``
            -   Number of records in the space.
                This metric always has 2 labels: ``{name="test", engine="memtx"}``,
                where ``name`` is the name of the space and
                ``engine`` is the engine of the space.
        *   -   ``tnt_space_bsize``
            -   Total number of bytes in all tuples.
                This metric always has 2 labels: ``{name="test", engine="memtx"}``,
                where ``name`` is the name of the space
                and ``engine`` is the engine of the space.
        *   -   ``tnt_space_index_bsize``
            -   Total number of bytes taken by the index.
                This metric always has 2 labels: ``{name="test", index_name="pk"}``,
                where ``name`` is the name of the space and
                ``index_name`` is the name of the index.
        *   -   ``tnt_space_total_bsize``
            -   Total size of tuples and all indexes in the space.
                This metric always has 2 labels: ``{name="test", engine="memtx"}``,
                where ``name`` is the name of the space and
                ``engine`` is the engine of the space.
        *   -   ``tnt_space_count``
            -   Total tuple count for vinyl.
                This metric always has 2 labels: ``{name="test", engine="vinyl"}``,
                where ``name`` is the name of the space and
                ``engine`` is the engine of the space. For vinyl this metric is disabled 
                by default and can be enabled only with global variable setup:
                ``rawset(_G, 'include_vinyl_count', true)``.

..  _metrics-reference-network:

Network
-------

Network activity stats.
These metrics can be used to monitor network load, usage peaks, and traffic drops.

Sent bytes:

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_net_sent_total``
            -   Bytes sent from the instance over the network since the instance's start time
        
Received bytes:

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_net_received_total``
            -   Bytes received by the instance since start time

Connections:

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_net_connections_total``
            -   Number of incoming network connections since the instance's start time
        *   -   ``tnt_net_connections_current``
            -   Number of active network connections

Requests:

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_net_requests_total``
            -   Number of network requests the instance has handled since its start time
        *   -   ``tnt_net_requests_current``
            -   Number of pending network requests

..  _metrics-reference-fibers:

Fibers
------

Provides the statistics for :ref:`fibers <fiber-fibers>`.
If your application creates a lot of fibers,
you can use the metrics below to monitor fiber count and memory usage.

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_fiber_count``
            -   Number of fibers
        *   -   ``tnt_fiber_csw``
            -   Overall number of fiber context switches
        *   -   ``tnt_fiber_memalloc``
            -   Amount of memory reserved for fibers
        *   -   ``tnt_fiber_memused``
            -   Amount of memory used by fibers

..  _metrics-reference-operations:

Operations
----------

You can collect iproto requests an instance has processed
and aggregate them by request type.
This may help you find out what operations your clients perform most often.

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_stats_op_total``
            -   Total number of calls since server start

To distinguish between request types, this metric has the ``operation`` label.
For example, it can look as follows: ``{operation="select"}``.
For the possible request types, check the table below.

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``auth``
            -   Authentication requests
        *   -   ``call``
            -   Requests to execute stored procedures
        *   -   ``delete``
            -   Delete calls
        *   -   ``error``
            -   Requests resulted in an error
        *   -   ``eval``
            -   Calls to evaluate Lua code
        *   -   ``execute``
            -   Execute SQL calls
        *   -   ``insert``
            -   Insert calls
        *   -   ``prepare``
            -   SQL prepare calls
        *   -   ``replace``
            -   Replace calls
        *   -   ``select``
            -   Select calls
        *   -   ``update``
            -   Update calls
        *   -   ``upsert``
            -   Upsert calls

..  _metrics-reference-replication:

Replication
-----------

Provides the current replication status.
Learn more about :ref:`replication in Tarantool <replication-mechanism>`.

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_info_lsn``
            -   LSN of the instance.
        *   -   ``tnt_info_vclock``
            -   LSN number in vclock.
                This metric always has the label ``{id="id"}``,
                where ``id`` is the instance's number in the replica set.
        *   -   ``tnt_replication_replica_<id>_lsn`` / ``tnt_replication_master_<id>_lsn``
            -   LSN of the master/replica, where
                ``id`` is the instance's number in the replica set.
        *   -   ``tnt_replication_<id>_lag``
            -   Replication lag value in seconds, where
                ``id`` is the instance's number in the replica set.

..  _metrics-reference-runtime:

Runtime
-------

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_runtime_lua``
            -   Lua garbage collector size in bytes
        *   -   ``tnt_runtime_used``
            -   Number of bytes used for the Lua runtime

..  _metrics-reference-cartridge:

Cartridge
---------

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_cartridge_issues``
            -   Number of :ref:`instance issues <cartridge.issues>`.
                This metric always has the label ``{level="critical"}``, where
                ``level`` is the level of the issue:

                *   ``critical`` is associated with critical instance problems,
                    such as the case when there is more than 90% memory used.
                *   ``warning`` is associated with other cluster problems,
                    such as replication issues on the instance.

        *   -   ``tnt_clock_delta``
            -   Clock drift across the cluster.
                This metric always has the label ``{delta="..."}``,
                which has the following possible values:

                *   ``max``---difference with the fastest clock (always positive)
                *   ``min``---difference with the slowest clock (always negative).

..  _metrics-reference-luajit:

LuaJIT metrics
--------------

LuaJIT metrics provide an insight into the work of the Lua garbage collector.
These metrics are available in Tarantool 2.6 and later.

General JIT metrics:

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``lj_jit_snap_restore``
            -   Overall number of snap restores
        *   -   ``lj_jit_trace_num``
            -   Number of JIT traces
        *   -   ``lj_jit_trace_abort``
            -   Overall number of abort traces
        *   -   ``lj_jit_mcode_size``
            -   Total size of allocated machine code areas

JIT strings:

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``lj_strhash_hit``
            -   Number of strings being interned
        *   -   ``lj_strhash_miss``
            -   Total number of string allocations

GC steps:

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``lj_gc_steps_atomic``
            -   Count of incremental GC steps (atomic state)
        *   -   ``lj_gc_steps_sweepstring``
            -   Count of incremental GC steps (sweepstring state)
        *   -   ``lj_gc_steps_finalize``
            -   Count of incremental GC steps (finalize state)
        *   -   ``lj_gc_steps_sweep``
            -   Count of incremental GC steps (sweep state)
        *   -   ``lj_gc_steps_propagate``
            -   Count of incremental GC steps (propagate state)
        *   -   ``lj_gc_steps_pause``
            -   Count of incremental GC steps (pause state)

Allocations:

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``lj_gc_strnum``
            -   Number of allocated ``string`` objects
        *   -   ``lj_gc_tabnum``
            -   Number of allocated ``table`` objects
        *   -   ``lj_gc_cdatanum``
            -   Number of allocated ``cdata`` objects
        *   -   ``lj_gc_udatanum``
            -   Number of allocated ``udata`` objects
        *   -   ``lj_gc_freed``
            -   Total amount of freed memory
        *   -   ``lj_gc_total``
            -   Current allocated Lua memory
        *   -   ``lj_gc_allocated``
            -   Total amount of allocated memory

..  _metrics-reference-psutils:

CPU metrics
-----------

The following metrics provide CPU usage statistics.
They are only available on Linux.

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_cpu_count``
            -   Total number of processors configured by the operating system
        *   -   ``tnt_cpu_total``
            -   Host CPU time
        *   -   ``tnt_cpu_thread``
            -   Tarantool thread CPU time.
                This metric always has the labels
                ``{kind="user", thread_name="tarantool", thread_pid="pid", file_name="init.lua"}``,
                where:

                *   ``kind`` can be either ``user`` or ``system``
                *   ``thread_name`` is ``tarantool``, ``wal``, ``iproto``, or ``coio``
                *   ``file_name`` is the entrypoint file name, for example, ``init.lua``.

There are also two cross-platform metrics, which can be obtained with a ``getrusage()`` call.

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_cpu_user_time``
            -   Tarantool CPU user time
        *   -   ``tnt_cpu_system_time``
            -   Tarantool CPU system time

..  _metrics-reference-vinyl:

Vinyl
-----

Vinyl metrics provide :ref:`vinyl engine <engines-vinyl>` statistics.

Disk
~~~~

The disk metrics are used to monitor overall data size on disk.

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_vinyl_disk_data_size``
            -   Amount of data in bytes stored in the ``.run`` files
                located in :ref:`vinyl_dir <cfg_basic-vinyl_dir>`
        *   -   ``tnt_vinyl_disk_index_size``
            -   Amount of data in bytes stored in the ``.index`` files
                located in :ref:`vinyl_dir <cfg_basic-vinyl_dir>`

.. _metrics-reference-vinyl_regulator:

Regulator
~~~~~~~~~

The vinyl regulator decides when to commence disk IO actions.
It groups activities in batches so that they are more consistent and
efficient.

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_vinyl_regulator_dump_bandwidth``
            -   Estimated average dumping rate, bytes per second.
                The rate value is initially 10485760 (10 megabytes per second).
                It is recalculated depending on the the actual rate.
                Only significant dumps that are larger than 1 MB are used for estimating.
        *   -   ``tnt_vinyl_regulator_write_rate``
            -   Actual average rate of performing write operations, bytes per second.
                The rate is calculated as a 5-second moving average.
                If the metric value is gradually going down,
                this can indicate disk issues.
        *   -   ``tnt_vinyl_regulator_rate_limit``
            -   Write rate limit, bytes per second.
                The regulator imposes the limit on transactions
                based on the observed dump/compaction performance.
                If the metric value is down to approximately ``10^5``,
                this indicates issues with the disk
                or the :ref:`scheduler <metrics-vinyl-scheduler>`.
        *   -   ``tnt_vinyl_regulator_dump_watermark``
            -   Maximum amount of memory in bytes used
                for in-memory storing of a vinyl LSM tree.
                When this maximum is accessed, a dump must occur.
                For details, see :ref:`engines-algorithm_filling_lsm`.
                The value is slightly smaller
                than the amount of memory allocated for vinyl trees,
                reflected in the :ref:`vinyl_memory <cfg_storage-vinyl_memory>` parameter.

Transactional activity
~~~~~~~~~~~~~~~~~~~~~~

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_vinyl_tx_commit``
            -   Counter of commits (successful transaction ends)
                Includes implicit commits: for example, any insert operation causes a
                commit unless it is within a
                :doc:`/reference/reference_lua/box_txn_management/begin`\ --\ :doc:`/reference/reference_lua/box_txn_management/commit`
                block.
        *   -   ``tnt_vinyl_tx_rollback``
            -   Сounter of rollbacks (unsuccessful transaction ends).
                This is not merely a count of explicit
                :doc:`/reference/reference_lua/box_txn_management/rollback`
                requests---it includes requests that ended with errors.
        *   -   ``tnt_vinyl_tx_conflict``
            -   Counter of conflicts that caused transactions to roll back.
                The ratio ``tnt_vinyl_tx_conflict / tnt_vinyl_tx_commit``
                above 5% indicates that vinyl is not healthy.
                At that moment, you'll probably see a lot of other problems with vinyl.
        *   -   ``tnt_vinyl_tx_read_views``
            -   Current number of read views---that is, transactions
                that entered the read-only state to avoid conflict temporarily.
                Usually the value is ``0``.
                If it stays non-zero for a long time, it is indicative of a memory leak.

Memory
~~~~~~

The following metrics show state memory areas used by vinyl for caches and write buffers.

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_vinyl_memory_tuple_cache``
            -   Amount of memory in bytes currently used to store tuples (data)
        *   -   ``tnt_vinyl_memory_level0``
            -   "Level 0" (L0) memory area, bytes.
                L0 is the area that vinyl can use for in-memory storage of an LSM tree.
                By monitoring this metric, you can see when L0 is getting close to its
                maximum (``tnt_vinyl_regulator_dump_watermark``),
                at which time a dump will occur.
                You can expect L0 = 0 immediately after the dump operation is completed.
        *   -   ``tnt_vinyl_memory_page_index``
            -   Amount of memory in bytes currently used to store indexes.
                If the metric value is close to :ref:`vinyl_memory <cfg_storage-vinyl_memory>`,
                this indicates that :ref:`vinyl_page_size <cfg_storage-vinyl_page_size>`
                was chosen incorrectly.
        *   -   ``tnt_vinyl_memory_bloom_filter``
            -   Amount of memory in bytes used by
                :ref:`bloom filters <vinyl-lsm_disadvantages_compression_bloom_filters>`.

..  _metrics-reference-vinyl_scheduler:

Scheduler
~~~~~~~~~

The vinyl scheduler invokes the :ref:`regulator <metrics-vinyl-regulator>` and
updates the related variables. This happens once per second.

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_vinyl_scheduler_tasks``
            -   Number of scheduler dump/compaction tasks.
                The metric always has label ``{status = <status_value>}``,
                where ``<status_value>`` can be one of the following:

                *   ``inprogress`` for currently running tasks
                *   ``completed`` for successfully completed tasks
                *   ``failed`` for tasks aborted due to errors.

        *   -   ``tnt_vinyl_scheduler_dump_time``
            -   Total time in seconds spent by all worker threads performing dumps.
        *   -   ``tnt_vinyl_scheduler_dump_count``
            -   Counter of dumps completed.
