require 'zeitwerk'
loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/cloudflare-rails.rb")
loader.setup

module CloudflareRails
end

loader.eager_load
