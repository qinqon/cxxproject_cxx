require 'cxxproject'
require 'cxxproject/context'
require 'cxxproject/utils/utils'
require 'cxxproject/utils/deprecated'

module Cxx
  class EvalContext
    include Cxxproject
    include Cxxproject::Context
    extend Deprecated

    attr_accessor :all_blocks

    # must be called to add building blocks
    def cxx_configuration(&block)
      @all_blocks = []
      block.call
    end

    def eval_project(project_text, project_file, pwd)
      @current_project_file = project_file
      @current_working_dir = pwd
      instance_eval(project_text)
    end

    def attach_sources(hash,bblock)
      if hash.has_key?(:sources)
        ss = hash[:sources]
        if ss.class == Array || ss.class == Rake::FileList
          bblock.set_sources(ss)
        else
          raise "sources need to be given in an Array or FileList, not a #{ss.class}"
        end
      end
    end

    def attach_includes(hash,bblock)
      bblock.set_includes(get_as_array(hash, :includes)) if hash.has_key?(:includes)
    end

    def attach_tags(hash, bblock)
      bblock.tags = Set.new
      if hash.has_key?(:tags)
        bblock.tags = hash[:tags].to_set
      end
    end

    # specify an executable
    # hash supports:
    # * :sources
    # * :includes
    # * :dependencies
    # * :output_dir
    def exe(name, hash)
      raise "not a hash" unless hash.is_a?(Hash)
      check_hash(hash,[:sources,:includes,:dependencies,:libpath,:output_dir, :tags])
      bblock = Cxxproject::Executable.new(name)
      attach_sources(hash,bblock)
      attach_includes(hash,bblock)
      attach_tags(hash, bblock)
      if hash.has_key?(:dependencies)
        bblock.set_dependencies(hash[:dependencies])
        hash[:dependencies].each { |d| bblock.add_lib_element(Cxxproject::HasLibraries::DEPENDENCY, d) }
      end
      bblock.set_output_dir(hash[:output_dir]) if hash.has_key?(:output_dir)
      all_blocks << bblock
      bblock
    end
    
    # specify an executable
    # hash supports:
    # * :sources
    # * :includes
    # * :dependencies
    # * :output_dir
    def shared(name, hash)
      raise "not a hash" unless hash.is_a?(Hash)
      check_hash(hash,[:sources,:includes,:dependencies,:libpath,:output_dir])
      bblock = Cxxproject::SharedLibrary.new(name)
      attach_sources(hash,bblock)
      attach_includes(hash,bblock)
      if hash.has_key?(:dependencies)
        bblock.set_dependencies(hash[:dependencies])
        hash[:dependencies].each { |d| bblock.add_lib_element(Cxxproject::HasLibraries::DEPENDENCY, d) }
      end
      bblock.set_output_dir(hash[:output_dir]) if hash.has_key?(:output_dir)
      all_blocks << bblock
    end

    # specify an executable
    # hash supports:
    # * :sources
    # * :includes
    # * :dependencies
    # * :output_dir
    # * :tags
    def shared_lib(name, hash)
      raise "not a hash" unless hash.is_a?(Hash)
      check_hash(hash, [:sources, :includes, :dependencies, :output_dir, :tags])
      bblock = Cxxproject::SharedLibrary.new(name)
      attach_sources(hash,bblock)
      attach_includes(hash,bblock)
      attach_tags(hash, bblock)
      if hash.has_key?(:dependencies)
        bblock.set_dependencies(hash[:dependencies])
        hash[:dependencies].each { |d| bblock.add_lib_element(Cxxproject::HasLibraries::DEPENDENCY, d) }
      end
      bblock.set_output_dir(hash[:output_dir]) if hash.has_key?(:output_dir)
      all_blocks << bblock
      bblock
    end

    # specify a static library
    # hash supports:
    # * :sources
    # * :includes
    # * :dependencies
    # * :toolchain
    # * :file_dependencies
    # * :output_dir
    # * :whole_archive
    # * :tags
    def static_lib(name, hash)
      raise "not a hash" unless hash.is_a?(Hash)
      check_hash(hash, [:sources, :includes, :dependencies, :toolchain, :file_dependencies, :output_dir, :whole_archive, :tags])
      raise ":sources need to be defined" unless hash.has_key?(:sources)
      bblock = Cxxproject::StaticLibrary.new(name, hash[:whole_archive])
      attach_sources(hash,bblock)
      attach_includes(hash,bblock)
      attach_tags(hash, bblock)
      bblock.set_tcs(hash[:toolchain]) if hash.has_key?(:toolchain)
      if hash.has_key?(:dependencies)
        bblock.set_dependencies(hash[:dependencies])
        hash[:dependencies].each { |d| bblock.add_lib_element(Cxxproject::HasLibraries::DEPENDENCY, d) }
      end
      bblock.file_dependencies = hash[:file_dependencies] if hash.has_key?(:file_dependencies)
      bblock.set_output_dir(hash[:output_dir]) if hash.has_key?(:output_dir)
      all_blocks << bblock
      bblock
    end

    deprecated_alias :source_lib, :static_lib

    def bin_lib(name, hash=Hash.new)
      raise "not a hash" unless hash.is_a?(Hash)
      check_hash(hash, [:includes, :lib_path])

      bblock = Cxxproject::BinaryLibrary.new(name)
      attach_includes(hash,bblock)
      bblock.add_lib_element(Cxxproject::HasLibraries::SEARCH_PATH, hash[:lib_path], true) if hash.has_key?(:lib_path)
      return bblock
    end

    # specify some binary libs
    # returns all binary libs as array
    def bin_libs(names, hash=Hash.new)
      raise "not a hash" unless hash.is_a?(Hash)
      check_hash(hash, [:includes, :lib_path])

      mapped = names.map{|n|n.to_s}
      return mapped.map{|name|bin_lib(name, hash)}
    end

    def compile(name, hash)
      raise "not a hash" unless hash.is_a?(Hash)
      check_hash(hash,[:sources,:includes])
      bblock = Cxxproject::SingleSource.new(name)
      attach_sources(hash,bblock)
      attach_includes(hash,bblock)
      all_blocks << bblock
    end

    def custom(name, hash)
      raise "not a hash" unless hash.is_a?(Hash)
      check_hash(hash,[:execute, :dependencies])
      bblock = Cxxproject::CustomBuildingBlock.new(name)
      bblock.set_actions(hash[:execute]) if hash.has_key?(:execute)
      if hash.has_key?(:dependencies)
        bblock.set_dependencies(hash[:dependencies])
      end
      all_blocks << bblock
    end
end
end
