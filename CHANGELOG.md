# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Changed
- Renamed `info_vclock_{ID}` metric to `info_vclock`, moved `{ID}` to tags
- Renamed `stat_op_{OP_TYPE}_total` metric to `stat_op_total`, moved `{OP_TYPE}` to tags
- Renamed `stat_op_{OP_TYPE}_rps` metric to `stat_op_rps`, moved `{OP_TYPE}` to tags
- Renamed `space_index_{IDX_NAME}_bsize` to `space_index_bsize`, moved `{IDX_NAME}` to tags

## [0.1.8] - 2020-01-15
### Added
- Ability to set labels globally for each metric
