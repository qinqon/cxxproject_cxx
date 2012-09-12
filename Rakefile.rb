require "bundler/gem_tasks"
require './rake_helper/spec.rb'

task :package => :build
