# Cloudflare::Rails [![Gem Version](https://badge.fury.io/rb/cloudflare-rails.svg)](https://badge.fury.io/rb/cloudflare-rails)

This gem correctly configures Rails for [CloudFlare](https://www.cloudflare.com) so that `request.remote_ip` / `request.ip` both work correctly.

## Rails Compatibility

For Rails 5, use 0.2.x

For Rails 4.2, use 0.1.x

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

## Usage

This code will fetch CloudFlare's current [IPv4](https://www.cloudflare.com/ips-v4) and [IPv6](https://www.cloudflare.com/ips-v6) lists, store them in `Rails.cache`, and add them to `config.cloudflare.ips`.

You can configure the HTTP `timeout` and `expires_in` cache parameters inside of your rails config:
```
config.cloudflare.expires_in = 12.hours # default value
config.cloudfalre.timeout = 5.seconds # default value
```

## Alternatives

[actionpack-cloudflare](https://github.com/customink/actionpack-cloudflare) simpler approach using the `CF-Connecting-IP` header. 

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/modosc/cloudflare-rails.
