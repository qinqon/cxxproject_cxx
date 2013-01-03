require 'cxx'

projects = Dir.glob('basic/*/project.rb')
cxx(projects, 'out', 'gcc', '.')
