# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

require 'bundler/setup'
require 'pry'

# Only the parts of rails we want to use
require 'action_controller/railtie'
require 'action_view/railtie'
require 'rails/test_unit/railtie'

# pull in rspec/rails before cloudflare/rails since that'll pull in rails which
# matches the ordering in a rails app
require 'rspec/rails'
require 'webmock/rspec'

if ENV['RACK_ATTACK'] == 'first'
  # pull in rack/attack first to make sure patches work with it
  require 'rack/attack'
end

require 'cloudflare-rails'

if ENV['RACK_ATTACK'] == 'last'
  # pull in rack/attack last to make sure patches work with it
  require 'rack/attack'
end

RSpec.configure do |config|
  config.infer_base_class_for_anonymous_controllers = false
end
