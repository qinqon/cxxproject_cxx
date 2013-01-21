require 'cxx'
require 'cxxproject/utils/cleanup'

OUT_DIR='cxxbuild'

describe Rake::Task do
  compiler = 'gcc'

  before(:each) do
    Rake::application.options.silent = true
    Cxxproject::Utils.cleanup_rake
  end

  after(:each) do
    Cxxproject::Utils.cleanup_rake
    FileUtils.rm_rf('test.cc')
    FileUtils.rm_rf('test.h')
  end

  it 'should fail if source of object is missing' do
    expect {
      Cxxproject::StaticLibrary.new('testlib').set_sources(['test.cc'])
    }.to raise_exception
  end

  it 'should not fail if include-dependency of object is missing' do
    File.open('test.cc', 'w') do |io|
      io.puts('#include "test.h"')
    end

    File.open('test.h', 'w') do |io|
    end

    sl = Cxxproject::StaticLibrary.new('testlib').set_sources(['test.cc']).set_project_dir(".")
    cxx([], OUT_DIR, compiler, '.')

    task = Rake::application['lib:testlib']
    task.invoke
    task.failure.should == false

    Cxxproject::Utils.cleanup_rake

    FileUtils.rm_rf('test.h')
    File.open('test.cc', 'w') do |io|
    end

    sl = Cxxproject::StaticLibrary.new('testlib').set_sources(['test.cc']).set_project_dir(".")
    cxx([], OUT_DIR, compiler, '.')

    task = Rake::application[File.join(OUT_DIR, 'libs', 'libtestlib.a')]
    task.invoke
    task.failure.should == false

  end

end
