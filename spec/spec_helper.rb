# copied from https://codingdaily.wordpress.com/2011/01/14/test-a-gem-with-the-rails-3-stack/
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

ENV["RAILS_ENV"] ||= 'test'

require 'bundler/setup'
Bundler.setup

require 'rubygems'
require 'pry'
# Only the parts of rails we want to use
require "action_controller/railtie"
require 'action_view/railtie'
require "rails/test_unit/railtie"

if ENV['RACK_ATTACK']
  # pull in rack/attack to make sure patches work with it
  require 'rack/attack'
end

require 'rspec/rails'
require 'cloudflare/rails'
require 'webmock/rspec'

RSpec.configure do |config|
  config.infer_base_class_for_anonymous_controllers = false
end
