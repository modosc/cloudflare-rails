# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloudflare/rails/version'

Gem::Specification.new do |spec|
  spec.name          = "cloudflare-rails"
  spec.version       = Cloudflare::Rails::VERSION
  spec.authors       = ["jonathan schatz"]
  spec.email         = ["modosc@users.noreply.github.com"]

  spec.summary       = "This gem configures Rails for CloudFlare so that request.ip and request.remote_ip and work correctly."
  spec.description   = ""
  spec.homepage      = "https://github.com/modosc/cloudflare-rails"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 12.3.1"
  spec.add_development_dependency "rspec_junit_formatter", "~> 0.4.1"
  spec.add_development_dependency "rspec-rails", "~> 3.8.2"
  spec.add_development_dependency "rspec", "~> 3.8.0"
  spec.add_development_dependency "rubocop-airbnb", "~> 2.0.0"
  spec.add_development_dependency "webmock", "~> 3.6.0"
  spec.add_development_dependency "rack-attack", "~> 6.1.0"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "pry-byebug"

  spec.add_dependency "httparty"
  spec.add_dependency "rails", "~> 5.0"

  # we need Module#prepend
  spec.required_ruby_version = '>= 2.0'
end
