require 'active_support/core_ext/integer/time'

module CloudflareRails
  class Railtie < Rails::Railtie
    # setup defaults before we configure our app.
    DEFAULTS = {
      expires_in: 12.hours,
      timeout: 5.seconds
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
