require "active_support/core_ext/integer/time"

module Cloudflare
  module Rails
    class Railtie < ::Rails::Railtie
      # patch rack::request::helpers to use our cloudflare ips - this way request.ip is
      # correct inside of rack and rails
      module CheckTrustedProxies
        def trusted_proxy?(ip)
          matching = Importer.cloudflare_ips.any? do |proxy|
            begin
              proxy === ip
            rescue IPAddr::InvalidAddressError
            end
          end
          matching || super
        end
      end

      # patch ActionDispatch::RemoteIP to use our cloudflare ips - this way
      # request.remote_ip is correct inside of rails
      module RemoteIpProxies
        def proxies
          super + Importer.cloudflare_ips
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
        IPS_V4_URL = '/ips-v4/'.freeze
        IPS_V6_URL = '/ips-v6/'.freeze

        class << self
          def ips_v6
            fetch IPS_V6_URL
          end

          def ips_v4
            fetch IPS_V4_URL
          end

          def fetch(url)
            uri = URI("#{BASE_URL}#{url}")

            resp = Net::HTTP.start(uri.host,
                                   uri.port,
                                   use_ssl: true,
                                   read_timeout: ::Rails.application.config.cloudflare.timeout) do |http|
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

          def cloudflare_ips(refresh: false)
            @ips = nil if refresh
            @ips ||= (Importer.fetch_with_cache(:ips_v4) + Importer.fetch_with_cache(:ips_v6)).freeze
          rescue StandardError => e
            ::Rails.logger.error(e)
            []
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
