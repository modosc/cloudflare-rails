# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

module CloudflareRails
  class Railtie < Rails::Railtie
    # setup defaults before we configure our app.
    DEFAULTS = {
      expires_in: 12.hours,
      timeout: 5.seconds,
      # cap the TCP connect time so a blocked/blackholed egress to cloudflare.com
      # can't hold a request thread for Net::HTTP's (much larger) default.
      open_timeout: 5.seconds,
      # how long the fallback list is cached after a failed fetch before we retry
      # the network. short, so a transient outage self-heals quickly.
      error_expires_in: 1.minute,
      # serve the previous value to concurrent callers while one refreshes an
      # expired entry, collapsing the thundering herd against cloudflare.com.
      race_condition_ttl: 10.seconds
    }.freeze

    config.before_configuration do |app|
      app.config.cloudflare = ActiveSupport::OrderedOptions.new
      app.config.cloudflare.reverse_merge! DEFAULTS
    end

    initializer 'cloudflare_rails.configure_rails_initialization' do
      Rack::Request::Helpers.prepend CheckTrustedProxies

      ObjectSpace.each_object(Class)
                 .select do |c|
        c.included_modules.include?(Rack::Request::Helpers) &&
          c.included_modules.exclude?(CheckTrustedProxies)
      end
        .map { |c| c.prepend CheckTrustedProxies }

      ActionDispatch::RemoteIp.prepend RemoteIpProxies
    end
  end
end
