# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [5.0.0] - 2023-12-15
### Breaking Changes
- Change namespace from `Cloudflare::Rails` to `CloudflareRails`. This avoids issues with the [cloudflare](https://github.com/socketry/cloudflare) gem as well as the global `Rails` namespace.
- A static set of Cloudflare IP addresses will now be used as a fallback value in the case of Cloudflare API failures. These will not be stored in `Rails.cache` so each subsequent result will retry the Cloudflare calls. Once one suceeds the response will be cached and used.

### Added
- Use `zeitwerk` to manage file loading.

## [4.1.0] - 2023-10-06
- Add support for `rails` version `7.1.0`

## [4.0.0] - 2023-08-06
- Fix `appraisal` for ruby `3.x`
- properly scope railtie initializer (https://github.com/modosc/cloudflare-rails/pull/79)
- Drop support for unsupported `rails` version `6.0.x`

## [3.0.0] - 2023-01-30
- Drop support for unsupported `rails` version `5.2.x`
- Fetch and cache IPs lazily instead of upon initialization (https://github.com/modosc/cloudflare-rails/pull/52)

## [2.4.0] - 2022-02-22
- Add trailing slashes to reflect Cloudflare API URLs (https://github.com/modosc/cloudflare-rails/pull/53)

## [2.3.0] - 2021-10-22
-  Better handling of malformed IP addresses (https://github.com/modosc/cloudflare-rails/pull/49)

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
