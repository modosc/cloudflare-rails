# copied from https://codingdaily.wordpress.com/2011/01/14/test-a-gem-with-the-rails-3-stack/
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)


ENV["RAILS_ENV"] ||= 'test'

require 'rubygems'

# Only the parts of rails we want to use
# if you want everything, use "rails/all"
#require "rails/all"
require "action_controller/railtie"
require 'action_view/railtie'
require "rails/test_unit/railtie"

require 'cloudflare/rails'

root = File.expand_path(File.dirname(__FILE__))

require 'rspec/rails'
require 'webmock/rspec'

RSpec.configure do |config|
  config.infer_base_class_for_anonymous_controllers = false
end
