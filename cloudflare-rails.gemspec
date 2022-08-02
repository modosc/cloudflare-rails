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

  spec.add_development_dependency "bundler", ">= 2.1.2"
  spec.add_development_dependency "rake", "~> 13.0.1"
  spec.add_development_dependency "rspec_junit_formatter", "~> 0.5.1"
  spec.add_development_dependency "rspec-rails", "~> 5.0.1"
  spec.add_development_dependency "rspec", "~> 3.11.0"
  spec.add_development_dependency "rubocop-airbnb", "~> 4.0.0"
  spec.add_development_dependency "webmock", "~> 3.15.0"
  spec.add_development_dependency "rack-attack", "~> 6.6.1"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "appraisal"

  spec.add_dependency "railties", ">= 5.2", "< 7.1.0"
  spec.add_dependency "activesupport", ">= 5.2", "< 7.1.0"
  spec.add_dependency "actionpack", ">= 5.2", "< 7.1.0"

  # we need Module#prepend
  spec.required_ruby_version = '>= 2.0'
end
