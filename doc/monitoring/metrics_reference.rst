.. _metrics-reference:

===============================================================================
Metrics reference
===============================================================================

This page provides detailed description of metrics from module ``metrics``.

.. _memory-general:

-------------------------------------------------------------------------------
Memory general
-------------------------------------------------------------------------------

Those metrics provide a picture of the whole Tarantool instance.

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
To learn more about usage cases, see `this <https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_slab/#box-slab-info>`_

Available memory, bytes:

* ``tnt_slab_quota_size`` - the amount of memory available to store tuples and indexes, equals memtx_memory

* ``tnt_slab_arena_size`` - the total memory used for tuples and indexes together (including allocated, but currently free slabs)

* ``tnt_slab_items_size`` - the total amount of memory (including allocated, but currently free slabs) used only for tuples, no indexes

Memory usage, bytes:

* ``tnt_slab_quota_used`` - the amount of memory that is already distributed to the slab allocator

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

Those metrics provide information about spaces size.

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
