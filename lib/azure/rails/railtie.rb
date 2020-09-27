module Azure
  module Rails
    class Railtie < ::Rails::Railtie

      module RemoteIpAzure
        def calculate_ip
          # Set by the Rack web server, this is a single value.
          remote_addr = sanitize_ips(ips_from(@req.remote_addr)).last

          # Could be a CSV list and/or repeated headers that were concatenated.
          client_ips    = sanitize_ips(ips_from(@req.client_ip)).reverse
          forwarded_ips = sanitize_ips(@req.forwarded_for || []).reverse

          # +Client-Ip+ and +X-Forwarded-For+ should not, generally, both be set.
          # If they are both set, it means that either:
          #
          # 1) This request passed through two proxies with incompatible IP header
          #    conventions.
          # 2) The client passed one of +Client-Ip+ or +X-Forwarded-For+
          #    (whichever the proxy servers weren't using) themselves.
          #
          # Either way, there is no way for us to determine which header is the
          # right one after the fact. Since we have no idea, if we are concerned
          # about IP spoofing we need to give up and explode. (If you're not
          # concerned about IP spoofing you can turn the +ip_spoofing_check+
          # option off.)
          should_check_ip = @check_ip && client_ips.last && forwarded_ips.last
          if should_check_ip && !forwarded_ips.include?(client_ips.last)
            # We don't know which came from the proxy, and which from the user
            raise IpSpoofAttackError, "IP spoofing attack?! " \
              "HTTP_CLIENT_IP=#{@req.client_ip.inspect} " \
              "HTTP_X_FORWARDED_FOR=#{@req.x_forwarded_for.inspect}"
          end

          # We assume these things about the IP headers:
          #
          #   - X-Forwarded-For will be a list of IPs, one per proxy, or blank
          #   - Client-Ip is propagated from the outermost proxy, or is blank
          #   - REMOTE_ADDR will be the IP that made the request to Rack
          ips = [forwarded_ips, client_ips].flatten.compact

          # If every single IP option is in the trusted list, return the IP
          # that's furthest away
          filter_proxies(ips + [remote_addr]).first || ips.last || remote_addr
        end

        def sanitize_ips(ips) # :doc:
          ips.select do |ip|
            # Only return IPs that are valid according to the IPAddr#new method.
            range = IPAddr.new(ip).to_range
            # We want to make sure nobody is sneaking a netmask in.
            range.begin == range.end
          rescue ArgumentError
            nil
          end
        end
      end

      ActionDispatch::RemoteIp.prepend RemoteIpAzure
    end
  end
end
