# frozen_string_literal: true

module CloudflareRails
  # patch ActionDispatch::RemoteIP to use our cloudflare ips - this way
  # request.remote_ip is correct inside of rails
  module RemoteIpProxies
    def proxies
      super + Importer.cloudflare_ips
    end
  end
end
