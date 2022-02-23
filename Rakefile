require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :without_rack_attack do
  ENV.delete 'RACK_ATTACK'
  Rake::Task["spec"].reenable
  Rake::Task["spec"].invoke
end

task :with_rack_attack_first do
  ENV['RACK_ATTACK'] = 'first'
  Rake::Task["spec"].reenable
  Rake::Task["spec"].invoke
end

task :with_rack_attack_last do
  ENV['RACK_ATTACK'] = 'last'
  Rake::Task["spec"].reenable
  Rake::Task["spec"].invoke
end

task :default => [:without_rack_attack, :with_rack_attack_first, :with_rack_attack_last]
