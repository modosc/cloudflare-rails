# frozen_string_literal: true

module CloudflareRails
  module FallbackIps
    # fetched from https://www.cloudflare.com/ips-v4/ on 2023-12-10
    IPS_V4_BODY = <<~EOM
      173.245.48.0/20
      103.21.244.0/22
      103.22.200.0/22
      103.31.4.0/22
      141.101.64.0/18
      108.162.192.0/18
      190.93.240.0/20
      188.114.96.0/20
      197.234.240.0/22
      198.41.128.0/17
      162.158.0.0/15
      104.16.0.0/13
      104.24.0.0/14
      172.64.0.0/13
      131.0.72.0/22
    EOM

    # convert our body into a list of IpAddrs
    IPS_V4 = IPS_V4_BODY.split("\n").map { |ip| IPAddr.new ip }.freeze

    # from https://www.cloudflare.com/ips-v6/ on 2023-12-10
    IPS_V6_BODY = <<~EOM
      2400:cb00::/32
      2606:4700::/32
      2803:f800::/32
      2405:b500::/32
      2405:8100::/32
      2a06:98c0::/29
      2c0f:f248::/32
    EOM

    # convert our body into a list of IpAddrs
    IPS_V6 = IPS_V6_BODY.split("\n").map { |ip| IPAddr.new ip }.freeze
  end
end
