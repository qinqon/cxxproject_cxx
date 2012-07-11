GEM_VERSION = "0.1.0"

spec = Gem::Specification.new do |s|
  s.name = 'rubydsl'
  s.description = 'ruby-based dsl for cxxproject'
  s.summary = 'defines the method cxx_configuration'
  s.version = '0.1.0'
  s.author = 'christian koestlin'
  s.email = 'christian.koestlin@gmail.com'
  s.platform = Gem::Platform::RUBY
  s.files = FileList['lib/**/*.rb'].to_a
  s.require_path = 'lib'
  s.add_dependency 'cxxproject'
  s.has_rdoc = false
end
