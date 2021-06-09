require "active_support/core_ext/integer/time"

module Cloudflare
  module Rails
    class Railtie < ::Rails::Railtie
      # patch rack::request::helpers to use our cloudflare ips - this way request.ip is
      # correct inside of rack and rails
      module CheckTrustedProxies
        def trusted_proxy?(ip)
          ::Rails.application.config.cloudflare.ips.any? { |proxy| proxy === ip } || super
        end
      end

      # patch ActionDispatch::RemoteIP to use our cloudflare ips - this way
      # request.remote_ip is correct inside of rails
      module RemoteIpProxies
        def proxies
          super + ::Rails.application.config.cloudflare.ips
        end
      end

      class Importer
        # Exceptions contain the Net::HTTP
        # response object accessible via the {#response} method.
        class ResponseError < StandardError
          # Returns the response of the last request
          # @return [Net::HTTPResponse] A subclass of Net::HTTPResponse, e.g.
          # Net::HTTPOK
          attr_reader :response

          # Instantiate an instance of ResponseError with a Net::HTTPResponse object
          # @param [Net::HTTPResponse]
          def initialize(response)
            @response = response
            super(response)
          end
        end

        BASE_URL = 'https://www.cloudflare.com'.freeze
        IPS_V4_URL = '/ips-v4'.freeze
        IPS_V6_URL = '/ips-v6'.freeze

        class << self
          def ips_v6
            fetch IPS_V6_URL
          end

          def ips_v4
            fetch IPS_V4_URL
          end

          def fetch(url)
            uri = URI("#{BASE_URL}#{url}")

            resp = Net::HTTP.start(uri.host, uri.port,
              use_ssl: true, read_timeout: ::Rails.application.config.cloudflare.timeout) do |http|
              req = Net::HTTP::Get.new(uri)

              http.request(req)
            end

            if resp.is_a?(Net::HTTPSuccess)
              resp.body.split("\n").reject(&:blank?).map { |ip| IPAddr.new ip }
            else
              raise ResponseError, resp
            end
          end

          def fetch_with_cache(type)
            ::Rails.cache.fetch("cloudflare-rails:#{type}", expires_in: ::Rails.application.config.cloudflare.expires_in) do
              send type
            end
          end
        end
      end

      # setup defaults before we configure our app.
      DEFAULTS = {
        expires_in: 12.hours,
        timeout: 5.seconds,
        ips: [],
      }.freeze

      config.before_configuration do |app|
        app.config.cloudflare = ActiveSupport::OrderedOptions.new
        app.config.cloudflare.reverse_merge! DEFAULTS
      end

      # we set config.cloudflare.ips after_initialize so that our cache will
      # be correctly setup. we rescue and log errors so that failures won't prevent
      # rails from booting
      config.after_initialize do |app|
        [:ips_v4, :ips_v6].each do |type|
          begin
            ::Rails.application.config.cloudflare.ips += Importer.fetch_with_cache(type)
          rescue Importer::ResponseError => e
            ::Rails.logger.error "Cloudflare::Rails: Couldn't import #{type} blocks from CloudFlare: #{e.response}"
          rescue StandardError => e
            ::Rails.logger.error "Cloudflare::Rails: Got exception: #{e} for type: #{type}"
          end
        end
      end
      initializer "my_railtie.configure_rails_initialization" do
        Rack::Request::Helpers.prepend CheckTrustedProxies

        ObjectSpace.each_object(Class).
          select do |c|
            c.included_modules.include?(Rack::Request::Helpers) &&
            !c.included_modules.include?(CheckTrustedProxies)
          end.
          map { |c| c .prepend CheckTrustedProxies }

        ActionDispatch::RemoteIp.prepend RemoteIpProxies
      end
    end
  end
end
