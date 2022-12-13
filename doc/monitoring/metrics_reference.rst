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
        *   -   ``tnt_vinyl_tuples``
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

Requests in progress:

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_net_requests_in_progress_total``
            -   Total count of requests processed by tx thread
        *   -   ``tnt_net_requests_in_progress_current``
            -   Count of requests currently being processed in the tx thread

Requests placed in queues of streams:

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_net_requests_in_stream_total``
            -   Total count of requests, which was placed in queues of streams
                for all time
        *   -   ``tnt_net_requests_in_stream_current``
            -   Count of requests currently waiting in queues of streams

Since Tarantool 2.10 in each network metric has the label ``thread``, showing per-thread network statistics.

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

        *   -   ``tnt_fiber_amount``
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
        *   -   ``tnt_replication_lsn``
            -   LSN of the tarantool instance.
                This metric always has labels ``{id="id", type="type"}``, where
                ``id`` is the instance's number in the replica set,
                ``type`` is ``master`` or ``replica``.
        *   -   ``tnt_replication_lag``
            -   Replication lag value in seconds.
                This metric always has labels ``{id="id", stream="stream"}``,
                where ``id`` is the instance's number in the replica set,
                ``stream`` is ``downstream`` or ``upstream``.
        *   -   ``tnt_replication_status``
            -   This metrics equals 1 when replication status is "follow" and 0 otherwise.
                This metric always has labels ``{id="id", stream="stream"}``,
                where ``id`` is the instance's number in the replica set,
                ``stream`` is ``downstream`` or ``upstream``.

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
        *   -   ``tnt_runtime_tuple``
            -   Number of bytes used for the tuples (except tuples owned by memtx and vinyl)

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

        *   -   ``tnt_cartridge_cluster_issues``
            -   Sum of :ref:`instance issues <cartridge.issues>` number over cluster.

        *   -   ``tnt_clock_delta``
            -   Clock drift across the cluster.
                This metric always has the label ``{delta="..."}``,
                which has the following possible values:

                *   ``max`` -- difference with the fastest clock (always positive),
                *   ``min`` -- difference with the slowest clock (always negative).

        *   -   ``tnt_cartridge_failover_trigger_total``
            -   Count of failover triggers in cluster.

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

        *   -   ``lj_jit_snap_restore_total``
            -   Overall number of snap restores
        *   -   ``lj_jit_trace_num``
            -   Number of JIT traces
        *   -   ``lj_jit_trace_abort_total``
            -   Overall number of abort traces
        *   -   ``lj_jit_mcode_size``
            -   Total size of allocated machine code areas

JIT strings:

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``lj_strhash_hit_total``
            -   Number of strings being interned
        *   -   ``lj_strhash_miss_total``
            -   Total number of string allocations

GC steps:

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``lj_gc_steps_atomic_total``
            -   Count of incremental GC steps (atomic state)
        *   -   ``lj_gc_steps_sweepstring_total``
            -   Count of incremental GC steps (sweepstring state)
        *   -   ``lj_gc_steps_finalize_total``
            -   Count of incremental GC steps (finalize state)
        *   -   ``lj_gc_steps_sweep_total``
            -   Count of incremental GC steps (sweep state)
        *   -   ``lj_gc_steps_propagate_total``
            -   Count of incremental GC steps (propagate state)
        *   -   ``lj_gc_steps_pause_total``
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
        *   -   ``lj_gc_freed_total``
            -   Total amount of freed memory
        *   -   ``lj_gc_memory``
            -   Current allocated Lua memory
        *   -   ``lj_gc_allocated_total``
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

        *   -   ``tnt_cpu_number``
            -   Total number of processors configured by the operating system
        *   -   ``tnt_cpu_time``
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
                or the :ref:`scheduler <metrics-reference-vinyl_scheduler>`.
        *   -   ``tnt_vinyl_regulator_dump_watermark``
            -   Maximum amount of memory in bytes used
                for in-memory storing of a vinyl LSM tree.
                When this maximum is accessed, a dump must occur.
                For details, see :ref:`engines-algorithm_filling_lsm`.
                The value is slightly smaller
                than the amount of memory allocated for vinyl trees,
                reflected in the :ref:`vinyl_memory <cfg_storage-vinyl_memory>` parameter.
        *   -   ``tnt_vinyl_regulator_blocked_writers``
            -   The number of fibers that are blocked waiting
                for Vinyl level0 memory quota.

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
                requests -- it includes requests that ended with errors.
        *   -   ``tnt_vinyl_tx_conflict``
            -   Counter of conflicts that caused transactions to roll back.
                The ratio ``tnt_vinyl_tx_conflict / tnt_vinyl_tx_commit``
                above 5% indicates that vinyl is not healthy.
                At that moment, you'll probably see a lot of other problems with vinyl.
        *   -   ``tnt_vinyl_tx_read_views``
            -   Current number of read views -- that is, transactions
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

The vinyl scheduler invokes the :ref:`regulator <metrics-reference-vinyl_regulator>` and
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
        *   -   ``tnt_vinyl_scheduler_dump_total``
            -   Counter of dumps completed.

..  _metrics-reference-memory_event_loop:

Event loop metrics
------------------

Event loop tx thread information:

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_ev_loop_time``
            -   Event loop time (ms)
        *   -   ``tnt_ev_loop_prolog_time``
            -   Event loop prolog time (ms)
        *   -   ``tnt_ev_loop_epilog_time``
            -   Event loop epilog time (ms)


..  _metrics-reference-synchro:

Synchro
-------

Shows the current state of a synchronous replication.

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_synchro_queue_owner``
            -   Instance ID of the current synchronous replication master.

        *   -   ``tnt_synchro_queue_term``
            -   Current queue term.

        *   -   ``tnt_synchro_queue_len``
            -   How many transactions are collecting confirmations now.

        *   -   ``tnt_synchro_queue_busy``
            -   Whether the queue is processing any system entry (CONFIRM/ROLLBACK/PROMOTE/DEMOTE).

..  _metrics-reference-election:

Election
--------

Shows the current state of a replica set node in regards to leader election.

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_election_state``
            -   election state (mode) of the node.
                When election is enabled, the node is writable only in the leader state.
                Possible values:

                *   0 (``follower``) -- all the non-leader nodes are called followers
                *   1 (``candidate``) -- the nodes that start a new election round are called candidates.
                *   2 (``leader``) -- the node that collected a quorum of votes becomes the leader

        *   -   ``tnt_election_vote``
            -   ID of a node the current node votes for.
                If the value is 0, it means the node hasn’t voted in the current term yet.

        *   -   ``tnt_election_leader``
            -   Leader node ID in the current term.
                If the value is 0, it means the node doesn’t know which node is the leader in the current term.

        *   -   ``tnt_election_term``
            -   Current election term.

Memtx
-----

Memtx mvcc memory statistics.
Transaction manager consists of two parts:
- the transactions themselves (TXN section)
- MVCC

..  _metrics-reference-memtx_txn:

TXN
~~~

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   - ``tnt_memtx_tnx_statements`` are the transaction statements.
            -   For example, the user started a transaction and made an action in it `space:replace{0, 1}`.
                Under the hood, this operation will turn into ``statement`` for the current transaction.
                This metric always has the label ``{kind="..."}``,
                which has the following possible values:

                *   ``total``
                    The number of bytes that are allocated for the statements of all current transactions.
                *   ``average``
                    Average bytes used by transactions for statements
                    (`txn.statements.total` bytes / number of open transactions).
                *   ``max``
                    The maximum number of bytes used by one the current transaction for statements.

        *   - ``tnt_memtx_tnx_user``
            -   In Tarantool C API there is a function `box_txn_alloc()`.
                By using this function user can allocate memory for the current transaction.
                This metric always has the label ``{kind="..."}``,
                which has the following possible values:

                *   ``total``
                    Memory allocated by the `box_txn_alloc()` function on all current transactions.
                *   ``average``
                    Transaction average (total allocated bytes / number of all current transactions).
                *   ``max``
                    The maximum number of bytes allocated by `box_txn_alloc()` function per transaction.

        *   - ``tnt_memtx_tnx_system``
            -   There are internals: logs, savepoints.
                This metric always has the label ``{kind="..."}``,
                which has the following possible values:

                *   ``total``
                    Memory allocated by internals on all current transactions.
                *   ``average``
                    Average allocated memory by internals (total memory / number of all current transactions).
                *   ``max``
                    The maximum number of bytes allocated by internals per transaction.

.. _metrics-reference-memtx_mvcc:

MVCC
~~~~

``mvcc`` is responsible for the isolation of transactions.
It detects conflicts and makes sure that tuples that are no longer in the space, but read by some transaction
(or can be read) have not been deleted.

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   - ``tnt_memtx_mvcc_trackers``
            -   Trackers that keep track of transaction reads.
                This metric always has the label ``{kind="..."}``,
                which has the following possible values:

                *   ``total``
                    Trackers of all current transactions are allocated in total (in bytes).
                *   ``average``
                    Average for all current transactions (total memory bytes / number of transactions).
                *   ``max``
                    Maximum trackers allocated per transaction (in bytes).

        *   - ``tnt_memtx_mvcc_conflicts``
            -   Allocated in case of transaction conflicts.
                This metric always has the label ``{kind="..."}``,
                which has the following possible values:

                *   ``total``
                    Bytes allocated for conflicts in total.
                *   ``average``
                    Average for all current transactions (total memory bytes / number of transactions).
                *   ``max``
                    Maximum bytes allocated for conflicts per transaction.


~~~~~~
Tuples
~~~~~~

Saved tuples are divided into 3 categories: ``used``, ``read_view``, ``tracking``.

Each category has two metrics:
- ``retained`` tuples - they are no longer in the index, but MVCC does not allow them to be removed.
- ``stories`` - MVCC is based on the story mechanism, almost every tuple has a story.
This is a separate metric because even the tuples that are in the index can have a story.
So ``stories`` and ``retained`` need to be measured separately.

..  container:: table

    ..  list-table::
        :widths: 25 75
        :header-rows: 0

        *   -   ``tnt_memtx_mvcc_tuples_used_stories``
            -   Tuples that are used by active read-write transactions.
                This metric always has the label ``{kind="..."}``,
                which has the following possible values:

                *   ``count``
                    Number of ``used`` tuples / number of stories.
                *   ``total``
                    Amount of bytes used by stories ``used`` tuples.

        *   -   ``tnt_memtx_mvcc_tuples_used_retained``
            -   Tuples that are used by active read-write transactions.
                But they are no longer in the index, but MVCC does not allow them to be removed.
                This metric always has the label ``{kind="..."}``,
                which has the following possible values:

                *   ``count``
                    Number of retained ``used`` tuples / number of stories.
                *   ``total``
                    Amount of bytes used by retained ``used`` tuples.

        *   -   ``tnt_memtx_mvcc_tuples_read_view_stories``
            -   Tuples that are not used by active read-write transactions,
                but are used by read-only transactions (i.e. in read view).
                This metric always has the label ``{kind="..."}``,
                which has the following possible values:

                *   ``count``
                    Number of ``read_view`` tuples / number of stories.
                *   ``total``
                    Amount of bytes used by stories ``read_view`` tuples.

        *   -   ``tnt_memtx_mvcc_tuples_read_view_retained``
            -   Tuples that are not used by active read-write transactions,
                but are used by read-only transactions (i.e. in read view).
                This tuples are no longer in the index, but MVCC does not allow them to be removed.
                This metric always has the label ``{kind="..."}``,
                which has the following possible values:

                *   ``count``
                    Number of retained ``read_view`` tuples / number of stories.
                *   ``total``
                    Amount of bytes used by retained ``read_view`` tuples.

        *   -   ``tnt_memtx_mvcc_tuples_tracking_stories``
            -   Tuples that are not directly used by any transactions, but are used by MVCC to track reads.
                This metric always has the label ``{kind="..."}``,
                which has the following possible values:

                *   ``count``
                    Number of ``tracking`` tuples / number of tracking stories.
                *   ``total``
                    Amount of bytes used by stories ``tracking`` tuples.

        *   -   ``tnt_memtx_mvcc_tuples_tracking_retained``
            -   Tuples that are not directly used by any transactions, but are used by MVCC to track reads.
                This tuples are no longer in the index, but MVCC does not allow them to be removed.
                This metric always has the label ``{kind="..."}``,
                which has the following possible values:

                *   ``count``
                    Number of retained ``tracking`` tuples / number of stories.
                *   ``total``
                    Amount of bytes used by retained ``tracking`` tuples.
