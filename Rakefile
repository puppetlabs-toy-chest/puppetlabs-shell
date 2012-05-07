require 'rake'
require 'rspec/core/rake_task'

task :test => [:spec]

desc 'Run RSpec'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/{unit}/**/*.rb'
end
