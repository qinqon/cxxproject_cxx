require 'rake/clean'

SPEC_PATTERN ='spec/**/*_spec.rb'

require 'rspec/core/rake_task'
desc "Run examples"
RSpec::Core::RakeTask.new() do |t|
  t.pattern = SPEC_PATTERN
  if ENV['BUILD_SERVER']
    t.rspec_opts = '-r ./junit.rb -f JUnit -o build/test_details.xml'
  end
end

task :gem => [:spec]
