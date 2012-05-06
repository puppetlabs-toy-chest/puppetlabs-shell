require 'rake'
require 'rspec/core/rake_task'

task :test => [:spec]

desc 'Run RSpec'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/{unit}/**/*.rb'
end

desc 'Generate code coverage'
RSpec::Core::RakeTask.new(:coverage) do |t|
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end
