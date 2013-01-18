require 'rubygems'

require 'cxxproject'
require 'logger'
require 'pp'
require 'pathname'
require 'cxxproject/ext/rake'
require 'cxxproject/buildingblocks/building_blocks'
require 'cxxproject/toolchain/colorizing_formatter'
require 'cxxproject/plugin_context'
require 'cxx/eval_context'

module Cxx

  class RubyDsl
    attr_accessor :base_dir, :all_tasks, :build_dir

    def initialize(projects, build_dir, toolchain_name, base_dir='.', &option_block)
      @build_dir = build_dir
      toolchain = Cxxproject::Toolchain::Provider[toolchain_name]
      option_block.call(toolchain) if option_block
      raise "no provider with name \"#{toolchain_name}\" found" unless toolchain
      @base_dir = base_dir
      cd(@base_dir, :verbose => false) do
        @projects = projects.to_a
      end

      Rake::application.deriveIncludes = true

      initialize_logging(build_dir)
      @all_tasks = instantiate_tasks(toolchain, build_dir)

      create_generic_tasks
      create_tag_tasks
      create_console_colorization
      create_multitask
      create_dont_bail_on_first_task
      describe_clean_task

      load_nontoolchain_plugins
    end

    def load_nontoolchain_plugins
      registry = Frazzle::Registry.new('cxxproject', '_', '-')
      registry.get_all_plugins.select { |name|name.index('toolchain') == nil }.each do |plugin|
        registry.load_plugin(plugin, Cxxproject::PluginContext.new(self, Cxxproject::ALL_BUILDING_BLOCKS, @log))
      end
    end

    def initialize_logging(build_dir)
      @log = Logger.new(STDOUT)
      @log.formatter = proc { |severity, datetime, progname, msg|
        "#{severity}: #{msg}\n"
      }
      # Logger loglevels: fatal, error, warn, info, debug
      # Rake --verbose -> info
      # Rake --trace -> debug
      @log.level = Logger::ERROR
      @log.level = Logger::INFO if RakeFileUtils.verbose == true
      @log.level = Logger::DEBUG if Rake::application.options.trace
      @log.debug "initializing for build_dir: \"#{build_dir}\", base_dir: \"#{@base_dir}\""
    end

    def describe_clean_task
      Rake::Task[:clean].add_description('clean')
    end

    def create_dont_bail_on_first_task
      desc 'dont bail on first error'
      task :dont_bail_on_first_error do
        Rake::Task.bail_on_first_error = false
      end
    end

    def create_multitask
      desc 'set parallelization of multitask'
      task :multitask, :threads do |t, args|
        arg = args.threads
        if arg
          Rake::application.max_parallel_tasks = arg.to_i
        end
      end
    end

    def create_console_colorization
      # default is on
      Cxxproject::ColorizingFormatter.enabled = true
      desc 'Toggle colorization of console output (use true|t|yes|y|1|on for true ... everything else is false)'
      task :toggle_colorize, :on_off do |t, args|
        arg = args[:on_off] || 'false'
        on_off = arg.match(/(true|t|yes|y|1|on)$/) != nil
        Cxxproject::ColorizingFormatter.enabled = on_off
      end
    end

    def create_generic_tasks
      tasks = [:lib, :exe, :run]
      tasks << nil
      tasks.each { |i| create_filter_task_with_namespace(i) }
    end

    def create_tag_tasks
      desc 'invoke tagged building blocks'
      task :tag, :tag do |t, args|
        if args[:tag]
          current_tag = args[:tag]
          Rake::Task::tasks.select {|t|t.tags.include?(current_tag)}.each do |task|
            task.invoke
          end
        end
      end
    end

    def create_filter_task_with_namespace(basename)
      if basename
        desc "invoke #{basename} with filter"
        namespace basename do
          create_filter_task("#{basename}:")
        end
      else
        desc 'invoke with filter'
        create_filter_task('')
      end
    end

    def create_filter_task(basename)
      task :filter, :filter do |t, args|
        filter = ".*"
        if args[:filter]
          filter = "#{args[:filter]}"
        end
        filter = Regexp.new("#{basename}#{filter}")
        Rake::Task.tasks.each do |to_check|
          name = to_check.name
          if ("#{basename}:filter" != name)
            match = filter.match(name)
            if match
              to_check.invoke
            end
          end
        end
      end
    end

    def instantiate_tasks(toolchain, build_dir)
      check_for_project_configs

      if @log.debug?
        @log.debug "project_configs:"
        @projects.each { |c| @log.debug " *  #{c}" }
      end
      register_projects()
      Cxxproject::ALL_BUILDING_BLOCKS.values.each do |block|
        prepare_block(block, toolchain, build_dir)
      end
      Cxxproject::ALL_BUILDING_BLOCKS.values.inject([]) do |memo,block|
        @log.debug "creating tasks for block: #{block.name}/taskname: #{block.get_task_name} (#{block})"
        if block.name != block.get_task_name
          task block.name => block.get_task_name # create task with simple name of buildinblock
        end
        memo << block.convert_to_rake()
      end
    end

    def check_for_project_configs
      cd(@base_dir, :verbose => false) do
        @projects.each do |p|
          abort "project config #{p} cannot be found in #{Dir.pwd}!" unless File.exists?(p)
        end
      end
    end

    def prepare_block(block, toolchain, build_dir)
      block.set_tcs(toolchain) unless block.has_tcs?
      block.set_output_dir(Dir.pwd + "/" + build_dir)
      block.complete_init()
    end

    def register_projects()
      cd(@base_dir,:verbose => false) do |b|
        @projects.each_with_index do |project_file, i|
          @log.debug "register project #{project_file}"
          dirname = File.dirname(project_file)
          @log.debug "dirname for project was: #{dirname}"
          cd(dirname,:verbose => false) do | base_dir |
            @log.debug "register project #{project_file} from within directory: #{Dir.pwd}"
            eval_file(b, File.basename(project_file))
          end
        end
      end
    end

    def eval_file(b, project_file)
      loadContext = EvalContext.new
      project_text = File.read(File.basename(project_file))
      begin
        loadContext.eval_project(project_text, project_file, Dir.pwd)
      rescue Exception => e
        puts "problems with #{File.join(b, project_file)} in dir: #{Dir.pwd}"
        puts project_text
        raise e
      end

      loadContext.all_blocks.each do |block|
        block.
          set_project_dir(Dir.pwd).
          set_config_files([Dir.pwd + "/" + project_file])
      end
    end

    def define_project_info_task
      desc "shows your defined projects"
      task :project_info do
        Cxxproject::ALL_BUILDING_BLOCKS.each_value do |bb|
          pp bb
        end
      end
    end

  end
end

def cxx(projects, output_dir, toolchain_name, base_dir, &block)
  Cxx::RubyDsl.new(projects, output_dir, toolchain_name, base_dir, &block)
end
