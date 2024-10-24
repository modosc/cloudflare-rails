# CloudflareRails [![Gem Version](https://badge.fury.io/rb/cloudflare-rails.svg)](https://badge.fury.io/rb/cloudflare-rails)

This gem correctly configures Rails for [CloudFlare](https://www.cloudflare.com) so that `request.remote_ip` / `request.ip` both work correctly. It also exposes a `#cloudflare?` method on `Rack::Request`.

## Rails Compatibility

This gem requires `railties`, `activesupport`, and `actionpack` >= `7.1`. For older `rails` versions see the chart below:

| `rails` version | `cloudflare-rails` version |
| --------------- | -------------------------- |
| 7.0             | 5.0.1                      |
| 6.1             | 5.0.1                      |
| 6.0             | 3.0.0                      |
| 5.2             | 2.4.0                      |
| 5.1             | 2.0.0                      |
| 5.0             | 2.0.0                      |
| 4.2             | 0.1.0                      |

## Installation

Add this line to your application's `Gemfile`:

```ruby
group :production do
  # or :staging or :beta or whatever environments you are using cloudflare in.
  # you probably don't want this for :test or :development
  gem 'cloudflare-rails'
end
```

And then execute:

    $ bundle

### If you're using Kamal

If you're using Kamal 2 for deployments, `kamal-proxy` [won't forward headers to your Rails app while using SSL]([url](https://kamal-deploy.org/docs/configuration/proxy/#forward-headers)), unless you explicitly tell it to. Without this, `cloudflare-rails` won't work in a Kamal-deployed Rails app using SSL.

You need to add `forward_headers: true` to your `proxy` section, like this:
```yaml
proxy:
  ssl: true
  host: example.com
  forward_headers: true
```

## Problem

Using Cloudflare means it's hard to identify the IP address of incoming requests since all requests are proxied through Cloudflare's infrastructure. Cloudflare provides a [CF-Connecting-IP](https://support.cloudflare.com/hc/en-us/articles/200170986-How-does-Cloudflare-handle-HTTP-Request-headers-) header which can be used to identify the originating IP address of a request. However, this header alone doesn't verify a request is legitimate. If an attacker has found the actual IP address of your server they could spoof this header and masquerade as legitimate traffic.

`cloudflare-rails` mitigates this attack by checking that the originating ip address of any incoming connection is from one of Cloudflare's ip address ranges. If so, the incoming `X-Forwarded-For` header is trusted and used as the ip address provided to `rack` and `rails` (via `request.ip` and `request.remote_ip`). If the incoming connection does not originate from a Cloudflare server then the `X-Forwarded-For` header is ignored and the actual remote ip address is used.

## How it works

This code fetches and caches CloudFlare's current [IPv4](https://www.cloudflare.com/ips-v4) and [IPv6](https://www.cloudflare.com/ips-v6) lists. It then patches `Rack::Request::Helpers` and `ActionDispatch::RemoteIP` to treat these addresses as trusted proxies. The `X-Forwarded-For` header will then be trusted only from those ip addresses.

### Why not use `config.action_dispatch.trusted_proxies` or `Rack::Request.ip_filter?`

By default Rails includes the [ActionDispatch::RemoteIp](https://api.rubyonrails.org/classes/ActionDispatch/RemoteIp.html) middleware. This middleware uses a default list of [trusted proxies](https://github.com/rails/rails/blob/6b93fff8af32ef5e91f4ec3cfffb081d0553faf0/actionpack/lib/action_dispatch/middleware/remote_ip.rb#L36C5-L42). Any values from `config.action_dispatch.trusted_proxies` are appended to this list. If you were to set `config.action_dispatch.trusted_proxies` to the current list of Cloudflare IP addresses `request.remote_ip` would work correctly.

Unfortunately this does not fix `request.ip`. This method comes from the [Rack::Request](https://github.com/rack/rack/blob/main/lib/rack/request.rb) middleware. It has a separate implementation of [trusted proxies](https://github.com/rack/rack/blob/main/lib/rack/request.rb#L48-L56) and [ip filtering](https://github.com/rack/rack/blob/main/lib/rack/request.rb#L58C1-L59C1). The only way to use a different implementation is to set `Rack::Request.ip_filter` which expects a callable value. Providing a new one will override the old one so you'd lose the default values (all of which should be there). Those values aren't exported anywhere so your callable would now have to maintain _that_ list on top of the Cloudflare IPs.

These issues are why this gem patches both `Rack::Request::Helpers` and `ActionDispatch::RemoteIP` rather than using the built-in configuration methods.

## Prerequisites

You must have a [`cache_store`](https://guides.rubyonrails.org/caching_with_rails.html#configuration) configured in your `rails` application.

## Usage

You can configure the HTTP `timeout` and `expires_in` cache parameters inside of your `rails` config:

```ruby
config.cloudflare.expires_in = 12.hours # default value
config.cloudflare.timeout = 5.seconds # default value
```

## Blocking non-Cloudflare traffic

You can use the `#cloudflare?` method from this gem to block all non-Cloudflare traffic to your application. Here's an example of doing this with [`Rack::Attack`](https://github.com/rack/rack-attack):

```ruby
  Rack::Attack.blocklist('CloudFlare WAF bypass') do |req|
    !req.cloudflare?
  end
```

Note that the request may optionally pass through additional trusted proxies, so it will return `true` for any of these scenarios:

-   `REMOTE_ADDR: CloudFlare`
-   `REMOTE_ADDR: trusted_proxy`, `X_HTTP_FORWARDED_FOR: CloudFlare`
-   `REMOTE_ADDR: trusted_proxy`, `X_HTTP_FORWARDED_FOR: CloudFlare,trusted_proxy2`
-   `REMOTE_ADDR: trusted_proxy`, `X_HTTP_FORWARDED_FOR: untrusted,CloudFlare`

but it will return `false` if CloudFlare comes to the left of an untrusted IP in `X-Forwarded-For`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/modosc/cloudflare-rails.
