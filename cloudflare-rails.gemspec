lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloudflare_rails/version'

Gem::Specification.new do |spec|
  spec.name          = 'cloudflare-rails'
  spec.version       = CloudflareRails::VERSION
  spec.authors       = ['jonathan schatz']
  spec.email         = ['modosc@users.noreply.github.com']
  spec.summary       = 'This gem configures Rails for CloudFlare so that request.ip and request.remote_ip and work correctly.'
  spec.description   = ''
  spec.homepage      = 'https://github.com/modosc/cloudflare-rails'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'appraisal', '~> 2.5.0'
  spec.add_development_dependency 'bundler', '>= 2.1.2'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rack-attack', '~> 6.7.0'
  spec.add_development_dependency 'rake', '~> 13.1.0'
  spec.add_development_dependency 'rspec', '~> 3.12.0'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.6.0'
  spec.add_development_dependency 'rspec-rails', '~> 6.1.0'
  spec.add_development_dependency 'rubocop', '~> 1.60.2'
  spec.add_development_dependency 'rubocop-performance', '~> 1.20.2'
  spec.add_development_dependency 'rubocop-rails', '~> 2.23.1'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.28.0'
  spec.add_development_dependency 'webmock', '~> 3.19.1'

  spec.add_dependency 'actionpack', '>= 6.1', '< 7.2.0'
  spec.add_dependency 'activesupport', '>= 6.1', '< 7.2.0'
  spec.add_dependency 'railties', '>= 6.1', '< 7.2.0'
  spec.add_dependency 'zeitwerk', '>= 2.5.0'

  # rails 6.1 lists this as the minimum
  spec.required_ruby_version = '>= 2.5.0'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
