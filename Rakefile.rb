require "bundler/gem_tasks"
require './rake_helper/spec.rb'

task :package => :build

projects = ['frazzle',
            'cxxproject',
            'cxxproject_gcctoolchain']

def gems
  ['frazzle', 'cxxproject', 'cxx', 'cxxproject_gcctoolchain']
end

desc 'prepare acceptance tests'
task :prepare_accept do
  gems.each do |gem|
    cd "../#{gem}" do
      sh 'rm -rf pkg'
      sh 'rake package'
    end
  end
  gems.each do |gem|
    sh "gem install ../#{gem}/pkg/*.gem"
  end
end

desc 'run acceptance tests'
RSpec::Core::RakeTask.new(:accept) do |t|
  t.pattern = 'accept/**/*_spec.rb'
  if ENV['BUILD_SERVER']
    t.rspec_opts = '-r ./junit.rb -f JUnit -o build/test_details.xml'
  end
end
#
#desc 'cleanup all built gems'
#task :clean do
#  projects.each do |p|
#    cd "../#{p}" do
#      sh 'rm -rf pkg'
#    end
#  end
#end
#
#desc 'install prerequisites for build'
#task :wipe_gems do
#  sh "rvm --force gemset empty"
#end
#
#desc 'install all built gems'
#task :build_and_install_gems do
#  projects.each do |p|
#    cd "../#{p}" do
#      sh 'rm -rf pkg'
#      sh 'rake package'
#      sh 'rake install'
#    end
#  end
#end
