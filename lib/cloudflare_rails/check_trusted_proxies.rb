# frozen_string_literal: true

module CloudflareRails
  # patch rack::request::helpers to use our cloudflare ips - this way request.ip is
  # correct inside of rack and rails
  module CheckTrustedProxies
    def cloudflare_ip?(ip)
      Importer.cloudflare_ips.any? do |proxy|
        proxy === ip
      rescue IPAddr::InvalidAddressError
      end
    end

    def trusted_proxy?(ip)
      cloudflare_ip?(ip) || super
    end

    def cloudflare?
      remote_addresses = split_header(get_header('REMOTE_ADDR'))
      forwarded_for = self.forwarded_for || []

      # Select only the trusted prefix of REMOTE_ADDR + X_HTTP_FORWARDED_FOR
      trusted_proxies = (remote_addresses + forwarded_for).take_while do |ip|
        trusted_proxy?(ip)
      end

      trusted_proxies.any? do |ip|
        cloudflare_ip?(ip)
      end
    end
  end
end
