require "httparty"

module Cloudflare
  module Rails
    class Railtie < ::Rails::Railtie

      # patch rack::request to use our cloudflare ips - this way request.ip is
      # correct inside of rack and rails
      module CheckTrustedProxies
        def trusted_proxy?(ip)
          ::Rails.application.config.cloudflare.ips.any?{ |proxy| proxy === ip } || super
        end
      end

      Rack::Request.prepend CheckTrustedProxies

      # patch ActionDispatch::RemoteIP to use our cloudflare ips - this way
      # request.remote_ip is correct inside of rails
      module RemoteIpProxies
        def proxies
          super + ::Rails.application.config.cloudflare.ips
        end
      end

      ActionDispatch::RemoteIp.prepend RemoteIpProxies

      class Importer
        include HTTParty
        base_uri 'https://www.cloudflare.com'
        follow_redirects true
        default_options.update(verify: true)

        class ResponseError < HTTParty::ResponseError; end

        IPS_V4_URL = '/ips-v4'
        IPS_V6_URL = '/ips-v6'

        class << self
          def ips_v6
            fetch IPS_V6_URL
          end

          def ips_v4
            fetch IPS_V4_URL
          end

          def fetch(url)
            resp = get url, timeout: ::Rails.application.config.cloudflare.timeout
            if resp.success?
              resp.body.split("\n").reject(&:blank?).map{|ip| IPAddr.new ip}
            else
              raise ResponseError.new(resp.response)
            end
          end

          def fetch_with_cache(type)
            ::Rails.cache.fetch("cloudflare-rails:#{type}", expires_in: ::Rails.application.config.cloudflare.expires_in) do
              self.send type
            end
          end


        end
      end

      # setup defaults before we configure our app. 
      DEFAULTS = {
        expires_in: 12.hours,
        timeout: 5.seconds,
        ips: Array.new
      }

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
          rescue => e
            ::Rails.logger.error "Cloudflare::Rails: Got exception: #{e} for type:#{type}"
          end
        end

      end
    end
  end
end
        # bail if ActionDispatch::RemoteIp isn't already loaded
        # if app.config.middleware.middlewares.exclude? ActionDispatch::RemoteIp
        #   ::Rails.logger.error "Couldn't find ActionDispatch::RemoteIp middleware, skipping CloudFlare::Rails initialization"
        #   return false
        # end


        # change our default timeout if specified
      #  default_timeout app.config.cloudflare.timeout if app.config.cloudflare.timeout.present?

        #cf_config = app.config.cloudflare.reverse_merge Importer::DEFAULT_CONFIG

#        Importer.default_timeout Config.config


        # caching is here so that we have app.config.cloudflare in scope - i
        # suppose we could move this into fetch and take expires_in as a
        # param?

        # cloudflare_ips += ::Rails.cache.fetch("cloudflare-rails:ip_v4", expires_in: cf_config[:expires_in]) do
        #   ip_v4
        # end.map{|ip| IPAddr.new ip }
        #
        # cloudflare_ips += ::Rails.cache.fetch("cloudflare-rails:ip_v6", expires_in: cf_config[:expires_in]) do
        #   ip_v6
        # end.map{|ip| IPAddr.new "[#{ip}]" }
#
#         [:ips_v4, :ips_v6].each do |type|
#           begin
#             ips = ::Rails.cache.fetch("cloudflare-rails:#{type}", expires_in: cf_config[:expires_in]) do
#                     Importer.send type
#                   end
#             app.config.cloudflare.ips += ips if ips.present?
#           rescue Importer::ResponseError => e
#             ::Rails.logger.error "Cloudflare::Rails: Couldn't import #{type} blocks from CloudFlare: #{e.response}"
#           rescue => e
#             ::Rails.logger.error "Cloudflare::Rails: Got exception: #{e} for type:#{type}, cloudflare_ips: #{cloudflare_ips}"
#           end
#         end
#
#         if app.config.cloudflare.ips.present?
#           # i don't know what uses these beyond ActionDispatch::RemoteIp (which
#           # we are patching below) but we should go ahead and keep this in sync
#           # anyway
#           if app.config.action_dispatch.trusted_proxies.blank?
#             # this behavior is copied from:
#             #
#             # https://github.com/rails/rails/blob/a59a9b7f729870de6c9282bd8e2a7ed7f86fc868/actionpack/lib/action_dispatch/middleware/remote_ip.rb#L76
#             #
#             # we want to make the addition of cloudflare_ips as transparent as
#             # possible but by adding our array in we change the behavior of
#             # ActionDispatch::RemoteIp
#             app.config.action_dispatch.trusted_proxies = ActionDispatch::RemoteIp::TRUSTED_PROXIES + cloudflare_ips
#           elsif app.config.action_dispatch.trusted_proxies.respond_to?(:any)
#             app.config.action_dispatch.trusted_proxies += app.config.cloudflare.ips
#           else
#             app.config.action_dispatch.trusted_proxies = Array(app.config.action_dispatch.trusted_proxies) + ActionDispatch::RemoteIp::TRUSTED_PROXIES + app.config.cloudflare.ips
#           end
#
#           # now we have to patch ActionDispatch::RemoteIp since by the time we
#           # get here it's already been configured and initialized and we can't
#           # easily mess around with the middleware stack.
#           remote_ip_patch = Module.new
#
#           remote_ip_patch.instance_eval do
#             define_method :proxies do
#               @proxies + app.config.cloudflare.ips
#             end
#           end
#
#           # remote_ip_patch.const_set :CLOUDFLARE_IPS, cloudflare_ips
#           # pp "remote_ip_patch.constants is #{remote_ip_patch.constants}"
#           ActionDispatch::RemoteIp.prepend remote_ip_patch
# #          pp ActionDispatch::RemoteIp::CLOUDFLARE_IPS
#         end
#       end
#     end
#   end
# end
