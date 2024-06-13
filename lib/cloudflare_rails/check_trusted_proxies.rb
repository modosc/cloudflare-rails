# frozen_string_literal: true

module CloudflareRails
  # patch rack::request::helpers to use our cloudflare ips - this way request.ip is
  # correct inside of rack and rails
  module CheckTrustedProxies
    def trusted_proxy?(ip)
      matching = Importer.cloudflare_ips.any? do |proxy|
        proxy === ip
      rescue IPAddr::InvalidAddressError
      end
      matching || super
    end
  end
end
