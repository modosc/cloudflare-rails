# frozen_string_literal: true

require 'net/http'
require 'uri'

module CloudflareRails
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
        super
      end
    end

    BASE_URL = 'https://www.cloudflare.com'
    IPS_V4_URL = '/ips-v4/'
    IPS_V6_URL = '/ips-v6/'

    class << self
      def ips_v6
        fetch IPS_V6_URL
      end

      def ips_v4
        fetch IPS_V4_URL
      end

      def fetch(url)
        resp = http_get(URI("#{BASE_URL}#{url}"))
        raise ResponseError, resp unless resp.is_a?(Net::HTTPSuccess)

        parse_ips(resp)
      end

      # Returns a cache entry hash: { ok: Boolean, ips: Array<IPAddr> }.
      #
      # On success the real list is cached for `expires_in` (long).
      # On failure the fallback list is cached for `error_expires_in` (short) so a
      # blocked/slow upstream does not trigger a fresh outbound request on *every*
      # call (each of which could block a request thread up to the configured
      # timeouts). Once the short ttl lapses the next call retries the network, so
      # a transient outage self-heals without a process restart.
      def fetch_with_cache(type)
        config = Rails.application.config.cloudflare
        entry = Rails.cache.fetch(cache_key(type),
                                  expires_in: config.expires_in,
                                  # collapse the thundering herd that would otherwise hit
                                  # cloudflare.com when a cached entry expires under load.
                                  race_condition_ttl: config.race_condition_ttl) do
          { ok: true, ips: send(type) }
        end

        normalize_entry(entry)
      rescue StandardError => e
        Rails.logger.error "cloudflare-rails: error fetching ip addresses from Cloudflare (#{e}), falling back to defaults"
        cache_fallback(type)
      end

      def cloudflare_ips(refresh: false)
        @ips = nil if refresh
        return @ips if @ips

        v4 = fetch_with_cache(:ips_v4)
        v6 = fetch_with_cache(:ips_v6)
        ips = (v4[:ips] + v6[:ips]).freeze

        # Only memoize a fully successful fetch. While serving the (negatively
        # cached) fallback we deliberately leave @ips unset so the next call
        # re-enters fetch_with_cache and can recover once the short error ttl
        # lapses — otherwise a single early failure would pin the fallback for the
        # entire life of the process.
        @ips = ips if v4[:ok] && v6[:ok]
        ips
      end

      private

      def http_get(uri)
        Net::HTTP.start(uri.host,
                        uri.port,
                        use_ssl: true,
                        # without an explicit open_timeout Net::HTTP waits up to its default
                        # (60s in most rubies) to establish the TCP connection. if egress to
                        # cloudflare.com is blackholed this blocks a request thread for the
                        # full duration, so cap it explicitly.
                        open_timeout: Rails.application.config.cloudflare.open_timeout,
                        read_timeout: Rails.application.config.cloudflare.timeout) do |http|
          http.request(Net::HTTP::Get.new(uri))
        end
      end

      def parse_ips(resp)
        ips = resp.body.split("\n").reject(&:blank?).map { |ip| IPAddr.new ip }

        # an empty list is never a legitimate response and must not be cached as a
        # success — treat it like a failed fetch so we fall back instead.
        raise ResponseError, resp if ips.empty?

        ips
      end

      def cache_fallback(type)
        config = Rails.application.config.cloudflare
        fallback = { ok: false, ips: fallback_ips_for(type) }
        Rails.cache.write(cache_key(type), fallback, expires_in: config.error_expires_in)
        fallback
      end

      def cache_key(type)
        "cloudflare-rails:#{type}"
      end

      def fallback_ips_for(type)
        case type
        when :ips_v4 then CloudflareRails::FallbackIps::IPS_V4
        when :ips_v6 then CloudflareRails::FallbackIps::IPS_V6
        else []
        end
      end

      # Tolerate legacy cache entries written by older versions of this gem, which
      # stored a bare Array<IPAddr> instead of the { ok:, ips: } hash. This keeps
      # things working across a rolling deploy.
      def normalize_entry(entry)
        return entry if entry.is_a?(Hash)

        { ok: true, ips: Array(entry) }
      end
    end
  end
end
