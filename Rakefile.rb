require "bundler/gem_tasks"
require './rake_helper/spec.rb'

task :package => :build

projects = ['frazzle',
            'cxxproject',
            'cxxproject_gcctoolchain']

desc 'cleanup all built gems'
task :clean do
  projects.each do |p|
    cd "../#{p}" do
      sh 'rake clobber_package'
    end
  end
end

desc 'install prerequisites for build'
task :wipe_gems do
  sh "rvm --force gemset empty"
end

desc 'install all built gems'
task :build_and_install_gems do
  projects.each do |p|
    cd "../#{p}" do
      sh 'rm -rf pkg'
      sh 'rake package'
      sh 'rake install'
    end
  end
end
