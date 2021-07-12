# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- metrics registry refactoring to search with `O(1)` [#188](https://github.com/tarantool/metrics/issues/188)
- `ipairs` instead of `pairs` while iteration in `histogram` [#196](https://github.com/tarantool/metrics/issues/196)

### Fixed
- be gentle to http routes, don't leave gaps in the array
  [#246](https://github.com/tarantool/metrics/issues/246)
- allow to create summary without observations [#265](https://github.com/tarantool/metrics/issues/265)

### Added
- `tnt_clock_delta` metric to compute clock difference on instances

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
