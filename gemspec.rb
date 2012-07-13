spec = Gem::Specification.new do |s|
  s.name = 'cxxprojectrubydsl'
  s.description = 'ruby-based dsl for cxxproject'
  s.summary = 'defines the method cxx_configuration'
  s.version = '0.1.3'
  s.author = 'christian koestlin'
  s.email = 'christian.koestlin@gmail.com'
  s.platform = Gem::Platform::RUBY
  s.files = FileList['lib/**/*.rb', 'lib/**/*.template'].to_a
  s.require_path = 'lib'
  s.add_dependency 'cxxproject'
  s.add_dependency 'highline'

  s.executables = ['cxx']

  s.has_rdoc = false
end
