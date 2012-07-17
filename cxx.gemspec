# -*- encoding: utf-8 -*-
gem_name = 'cxx'
require File.expand_path("lib/#{gem_name}/version")

spec = Gem::Specification.new do |s|
  s.name = gem_name
  s.version = Cxx::VERSION

  s.description = 'ruby-based dsl for cxxproject'
  s.summary = 'defines the method cxx_configuration'
  s.author = 'christian koestlin'
  s.email = 'christian.koestlin@gmail.com'
  s.platform = Gem::Platform::RUBY
  s.files = `git ls-files`.split($\)
  s.require_path = 'lib'

  s.add_dependency 'cxxproject'
  s.add_dependency 'highline'

  s.executables = ['cxx']

  s.has_rdoc = false
end
