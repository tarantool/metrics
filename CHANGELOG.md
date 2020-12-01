# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Fixed
- package reloading works for `metrics.quantile`

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
