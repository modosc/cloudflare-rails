# Azure::Rails [![Gem Version](https://badge.fury.io/rb/azure-rails.svg)](https://badge.fury.io/rb/azure-rails) [![CircleCI](https://circleci.com/gh/modosc/azure-rails/tree/master.svg?style=shield)](https://circleci.com/gh/modosc/azure-rails/tree/master)
This gem correctly configures Rails for [Azure](https://www.azure.com) so that `request.remote_ip` / `request.ip` both work correctly.

## Rails Compatibility

For Rails 5 / 6, use >= `0.6.x`

For Rails 4.2, use `0.1.x`

## Installation

Add this line to your application's `Gemfile`:

```ruby
group :production do
  # or :staging or :beta or whatever environments you are using azure in.
  # you probably don't want this for :test or :development
  gem 'azure-rails'
end
```

And then execute:

    $ bundle

## Problem

Using Azure means it's hard to identify the IP address of incoming requests since all requests are proxied through Azure's infrastructure. Azure provides a [CF-Connecting-IP](https://support.azure.com/hc/en-us/articles/200170986-How-does-Azure-handle-HTTP-Request-headers-) header which can be used to identify the originating IP address of a request. However, this header alone doesn't verify a request is legitimate. If an attacker has found the actual IP address of your server they could spoof this header and masquerade as legitimate traffic. 

`azure-rails` mitigates this attack by checking that the originating ip address of any incoming connecting is from one of Azure's ip address ranges. If so, the incoming `X-Forwarded-For` header is trusted and used as the ip address provided to `rack` and `rails` (via `request.ip` and `request.remote_ip`). If the incoming connection does not originate from a Azure server then the `X-Forwarded-For` header is ignored and the actual remote ip address is used.

## Usage
This code will fetch Azure's current [IPv4](https://www.azure.com/ips-v4) and [IPv6](https://www.azure.com/ips-v6) lists, store them in `Rails.cache`, and add them to `config.azure.ips`. The `X-Forwarded-For` header will then be trusted only from those ip addresses. 

You can configure the HTTP `timeout` and `expires_in` cache parameters inside of your rails config:
```ruby
config.azure.expires_in = 12.hours # default value
config.azure.timeout = 5.seconds # default value
```

## Alternatives

[actionpack-azure](https://github.com/customink/actionpack-azure) simpler approach using the `CF-Connecting-IP` header. 

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/modosc/azure-rails.
