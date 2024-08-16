# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Use box.info.ro instead of box.cfg.read_only in replication metrics.

## [1.2.0] - 2024-07-09
### Added
- New Tarantool 3 metrics:
  - tnt_config_alerts
  - tnt_config_status

## [1.1.0] - 2024-05-17
### Added
- `metrics.cfg{}` `"all"` metasection for array `include` and `exclude`
  (`metrics.cfg{include={'all'}}` can be used instead of `metrics.cfg{include='all'}`,
  `metrics.cfg{exclude={'all'}}` can be used instead of `metrics.cfg{include='none'}`)

- `tnt_election_leader_idle` metric.

- Histogram now logs a warning if `observe` is called with `cdata` value.

### Changed

- Inconsistent metrics descrtiptions for memtx metrics.

- New memory metrics:
  - tnt_memtx_tuples_data_total
  - tnt_memtx_tuples_data_read_view
  - tnt_memtx_tuples_data_garbage
  - tnt_memtx_index_total
  - tnt_memtx_index_read_view
  - tnt_vinyl_memory_tuple

### Deprecated

- Using `cdata` values with `histogram:observe`.

## [1.0.0] - 2023-05-22
### Changed

- Don't export self replication status.

### Removed

- `cartridge.roles.metrics` moved to [cartridge-metrics-role](https://github.com/tarantool/cartridge-metrics-role) repository
  (**incompatible change**).

## [0.17.0] - 2023-03-23
### Added
- `metrics.cfg{}` -- a single entrypoint to setup the module:
  - `include` and `exclude` options with the same effect as in
    `enable_default_metrics(include, exclude)` (but its deprecated
    features already disabled);
  - `labels` options with the same effect as `set_global_labels(labels)`;
  - values and effect (like default metrics callbacks) are preserved
    between reloads;
  - does not deal with external features like cartridge HTTP setup
- Versioning support through `require('metrics')._VERSION`

### Changed
- Setup cartridge hotreload inside the role
- Extend `enable_default_metrics()` API:
  - `'all'` and `'none'` options for `include` argument,
  - simultaneous `include` and `exclude` arguments
    (`exclude` has higher priority)
- Build rock with cmake
- Override built-in metrics, if installed

### Deprecated
- Passing nonexistent metrics to `enable_default_metrics()`
- Using `{}` as `include` in `enable_default_metrics()`
  to enable all metrics
- Versioning support through `require('metrics').VERSION`

## [0.16.0] - 2023-01-27
### Added

- Handle to clear psutils metrics
- `invoke_callbacks` option for `metrics.collect()`
- Ability to set metainfo for collectors
- Set `metainfo.default` to `true` for all collectors
  from `enable_default_metrics()` and psutils collectors
- `default_only` option for `metrics.collect()`

### Fixed

- Fix `is_healthy` function to rely on membership state
- Fix psutils time metrics
- Fix missing psutils cpu count after clear

### Removed

- Set non-number values in `gauge:set`
- Deprecated metrics from previous releases

## [0.15.1] - 2022-09-20
### Added

 - `memtx` MVCC memory monitoring

### Fixed

- `tnt_synchro_queue_len` metric type
- Reset callbacks on hotreload
- Fix queries in quantile

## [0.15.0] - 2022-08-09
### Fixed

- Clean info about spaces and indexes after their drop
- Fixed error when indexing spaces

### Added

- Label `thread` for per thread reporting net statistics metrics.
- `tnt_cartridge_failover_trigger_total` metric
- New synchro and election metrics:
  - `tnt_synchro_queue_owner`
  - `tnt_synchro_queue_term`
  - `tnt_synchro_queue_len`
  - `tnt_synchro_queue_busy`
  - `tnt_election_state`
  - `tnt_election_vote`
  - `tnt_election_leader`
  - `tnt_election_term`
- Renamed LuaJit metrics:
  - `lj_gc_allocated_total`
  - `lj_gc_freed_total`
  - `lj_gc_steps_atomic_total`
  - `lj_gc_steps_finalize_total`
  - `lj_gc_steps_pause_total`
  - `lj_gc_steps_propagate_total`
  - `lj_gc_steps_sweep_total`
  - `lj_gc_steps_sweepstring_total`
  - `lj_jit_snap_restore_total`
  - `lj_jit_trace_abort_total`
  - `lj_strhash_hit_total`
  - `lj_strhash_miss_total`

### Deprecated

- Metrics:
  - `lj_gc_allocated`
  - `lj_gc_freed`
  - `lj_gc_steps_atomic`
  - `lj_gc_steps_finalize`
  - `lj_gc_steps_pause`
  - `lj_gc_steps_propagate`
  - `lj_gc_steps_sweep`
  - `lj_gc_steps_sweepstring`
  - `lj_jit_snap_restore`
  - `lj_jit_trace_abort`
  - `lj_strhash_hit`
  - `lj_strhash_miss`

### Removed

- Deprecated metrics from previous releases

## [0.14.0] - 2022-06-28
### Fixed

- Float numbers in Graphite exporter
- Signed timestamp in Graphite exporter
- Increase `Shared.make_key` performance in observations with empty label
- Forbid observation of non-number value in collectors (except `gauge:set`)
- Clean dead threads from `psutils.cpu` metric

### Added

- `tnt_cartridge_cluster_issues` metric

### Deprecated

- Set non-number values in `gauge:set`

### Removed

- HTTP middleware v2
- `enable_cartridge_metrics` function

## [0.13.0] - 2022-03-23
### Fixed

- Don't reset collectors when Cartridge roles hot reload
- `pairs` instead of `ipairs` in iterations over replication info

### Changed

- Type changed from `gauge` to `counter`:
  - `tnt_net_sent_total`
  - `tnt_net_received_total`
  - `tnt_net_connections_total`
  - `tnt_net_requests_total`
  - `tnt_stats_op_total`

### Added

- New metrics:
  - `tnt_vinyl_tuples` (same as `tnt_space_count`)
  - `tnt_fiber_amount` (same as `tnt_fiber_count`)
  - `lj_gc_memory` (same as `lj_gc_total`)
  - `tnt_cpu_number` (same as `tnt_cpu_count`)
  - `tnt_cpu_time` (same as `tnt_cpu_total`)
  - `tnt_vinyl_scheduler_dump_total` (same as `tnt_vinyl_scheduler_dump_count`)
  - `tnt_replication_lag`
  - `tnt_vinyl_regulator_blocked_writers`
  - `tnt_net_requests_in_progress_total`
  - `tnt_net_requests_in_progress_current`
  - `tnt_net_requests_in_stream_total`
  - `tnt_net_requests_in_stream_current`
  - `tnt_replication_lsn`
  - `tnt_replication_status`
  - `tnt_ev_loop_time`
  - `tnt_ev_loop_prolog_time`
  - `tnt_ev_loop_epilog_time`

### Deprecated

- Metrics:
  - `tnt_net_sent_rps`
  - `tnt_net_received_rps`
  - `tnt_net_connections_rps`
  - `tnt_net_requests_rps`
  - `tnt_stats_op_rps`
  - `tnt_space_count`
  - `tnt_fiber_count`
  - `lj_gc_total`
  - `tnt_cpu_count`
  - `tnt_cpu_total`
  - `tnt_vinyl_scheduler_dump_count`
  - `tnt_replication_<id>_lag`
  - `tnt_replication_master_<id>_lsn`
  - `tnt_replication_replica_<id>_lsn`

## [0.12.0] - 2021-11-18
### Changed
- Update `http` dependency to 1.1.1

### Fixed
- Cast number64 to json number in json export plugin [#321](https://github.com/tarantool/metrics/issues/321)

### Deprecated
- HTTP middleware v2

## [0.11.0] - 2021-09-23
### Added
- collector's method `remove` to clear observations with given label pairs [#263](https://github.com/tarantool/metrics/issues/263)
- `counter:reset()` method [#260](https://github.com/tarantool/metrics/issues/260)
- `tnt_read_only` metric [#275](https://github.com/tarantool/metrics/issues/275)

### Removed
- Average collector

### Fixed
- Throw an error when http_middelware is processing a wrong handler [#199](https://github.com/tarantool/metrics/issues/199)
- cartridge issues metric fails before cartridge.cfg() call [#298](https://github.com/tarantool/metrics/issues/298)

### Changed
- quantile metric is NAN if no samples provided for an age [#303](https://github.com/tarantool/metrics/issues/303)

## [0.10.0] - 2021-08-03
### Changed
- metrics registry refactoring to search with `O(1)` [#188](https://github.com/tarantool/metrics/issues/188)
- `ipairs` instead of `pairs` while iteration in `histogram` [#196](https://github.com/tarantool/metrics/issues/196)
- `set_export` function provide default metrics config to make role reloadable [#248](https://github.com/tarantool/metrics/issues/248)
- metrics registry refactoring to add and remove callbacks with `O(1)` [#276](https://github.com/tarantool/metrics/issues/276)

### Fixed
- be gentle to http routes, don't leave gaps in the array
  [#246](https://github.com/tarantool/metrics/issues/246)
- allow to create summary without observations [#265](https://github.com/tarantool/metrics/issues/265)

### Added
- `tnt_clock_delta` metric to compute clock difference on instances [#232](https://github.com/tarantool/metrics/issues/232)
- set custom global labels in config and with `set_labels` function [#259](https://github.com/tarantool/metrics/issues/259)
- allow to include and exclude default metrics in config and in `enable_default_metrics` function
  [#222](https://github.com/tarantool/metrics/issues/222)
- `unregister_callback` function [#262](https://github.com/tarantool/metrics/issues/262)

### Deprecated
- `enable_cartridge_metrics` function

## [0.9.0] - 2021-05-28
### Fixed
- cartridge metrics role fails to start without http [#225](https://github.com/tarantool/metrics/issues/225)
- quantile overflow after `fiber.yield()` [#235](https://github.com/tarantool/metrics/issues/235)
- role and module hot reload [#227](https://github.com/tarantool/metrics/issues/227), [#228](https://github.com/tarantool/metrics/issues/228)

### Changed
- `tnt_cartridge_issues` gathers only local issues [#211](https://github.com/tarantool/metrics/issues/211)

### Added
- Age buckets in `summary`

## [0.8.0] - 2021-04-13
### Added
- New default metrics: cpu_user_time, cpu_system_time
- Vinyl metrics

## [0.7.1] - 2021-03-18
### Added
- zone label support for Tarantool Cartridge >= '2.4.0'
- rpm packaging for CentOS 8, Fedora 30, 31, 32

## [0.7.0] - 2021-02-09
### Added
- instance health check plugin

## [0.6.1] - 2021-01-20
### Fixed
- package reloading works for `metrics.quantile`
- instance_name in alias label if no alias present

## [0.6.0] - 2020-12-01
### Fixed
- metrics.clear() disables default metrics
- cartridge role is permanent
- cartridge role configuration without clusterwide config
- graphite plugin kills previous workers on init
- graphite plugin format numbers without ULL/LL-suffixes
- graphite plugin time in seconds
- graphite plugin allows empty prefix

### Added
- Luajit platform metrics
- `enable_cartridge_metrics` function
- Cartridge issues gauge

### Changed
- CI on Github Actions

## [0.5.0] - 2020-09-18
### Added
- Summary collector

### Deprecated
- Average collector

## [0.4.0] - 2020-07-14
### Added
- New default metrics: cpu_total, cpu_thread
- histogram:observe_latency for measure latency of function call with example

## [0.3.0] - 2020-06-11
### Added
- Role for [tarantool/cartridge](https://github.com/tarantool/cartridge)
- Documentaion and examples on [tarantool/http server](https://github.com/tarantool/http) middleware

### Fixed
- Throw exception when `http_middleware.build_default_collector` is called with same name
- Attempt to index non-existent master vclock on a replica after the death of the master

## [0.2.0] - 2020-05-07
### Added
- [tarantool/http server](https://github.com/tarantool/http) middleware to collect http server metrics
### Fixed
- `collect` failure for vinyl metrics in strict mode
- prometheus exporter: render 0 for 0ULL value instead of +Inf
- Travis CI build failures
### Changed
- Renamed `info_vclock_{ID}` metric to `info_vclock`, moved `{ID}` to tags
- Renamed `stat_op_{OP_TYPE}_total` metric to `stat_op_total`, moved `{OP_TYPE}` to tags
- Renamed `stat_op_{OP_TYPE}_rps` metric to `stat_op_rps`, moved `{OP_TYPE}` to tags
- Renamed `space_index_{IDX_NAME}_bsize` to `space_index_bsize`, moved `{IDX_NAME}` to tags

## [0.1.8] - 2020-01-15
### Added
- Ability to set labels globally for each metric
