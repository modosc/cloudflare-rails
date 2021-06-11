# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.0] - 2021-06-11
- Fix typo in `actionpack` dependency

## [2.1.0] - 2021-06-11
### Breaking Changes
- Drop support for unsupported `rails` versions (`5.0.x` and `5.1.x`)

### Added
- use Net::HTTP instead of httparty ([pr](https://github.com/modosc/cloudflare-rails/pull/44))
- Add `rails 7.0.0.alpha` support

## [2.0.0] - 2021-02-17
### Breaking Changes
- Removed broad dependency on `rails`, replaced with explicit dependencies for `railties`, `activesupport`, and `actionpack` ( [issue](https://github.com/modosc/cloudflare-rails/issues/34) and [pr](https://github.com/modosc/cloudflare-rails/pull/35))

## [1.0.0] - 2020-09-29
### Added

- Fix various [loading order issues](https://github.com/modosc/cloudflare-rails/pull/25).
