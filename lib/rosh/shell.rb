require 'log_switch'
Dir[File.dirname(__FILE__) + '/builtin_commands/*.rb'].each(&method(:require))
Dir[File.dirname(__FILE__) + '/command_wrappers/*.rb'].each(&method(:require))
require_relative 'command_result'
require_relative 'environment'


class Rosh

  # Each Rosh Host provides a Shell that allows for executing shell commands on
  # that host.  You can run commands using two approaches: on-demand, where
  # commands are executed as they are encountered in your logic, and compiled,
  # where commands are gathered up, then all run when you call #process_all.
  #
  # All commands return a CommandResult, which contains an exit code, the Ruby
  # object that the command output represents, and, if the command was run over
  # SSH, the SSH output.
  class Shell
    extend LogSwitch
    include LogSwitch::Mixin

    @@builtin_commands = %i[cat cd ch cp exec history ls ps pwd ruby]
    @@wrapper_commands = %i[brew]

    def cat(file)
      Rosh::BuiltinCommands::Cat.new(file).send(@context)
    end

    def cd(path)
      result = Rosh::BuiltinCommands::Cd.new(path).send(@context)

      if result.exit_status.zero?
        @env[:pwd] = result.ruby_object
        log "pwd is now #{@env[:pwd]}"
      end

      result
    end

    def cp(source, destination)
      Rosh::BuiltinCommands::Cp.new(source, destination).send(@context)
    end

    def exec(cmd)
      Rosh::BuiltinCommands::Exec.new(cmd).send(@context)
    end

    def history
      history_array = @using_cli ? Readline::HISTORY.to_a : @non_cli_history
      Rosh::BuiltinCommands::History.new(history_array).send(@context)
    end

    def ls(path=nil)
      Rosh::BuiltinCommands::Ls.new(path).send(@context)
    end

    def ps
      Rosh::BuiltinCommands::Ps.new.send(@context)
    end

    def pwd(force=false)
      Rosh::BuiltinCommands::Pwd.new(force).send(@context)
    end

    def ruby(code)
      Rosh::BuiltinCommands::Ruby.new(code, get_binding).send(@context)
    end

    def save_command_set(name, &block)
      @command_sets[name] = block
    end

    def exec_command_set(name=nil)
      if name
        log "Executing command set '#{name}'"
        @command_sets[name].call(self)
      else
        @command_sets.each do |name, blk|
          log "Executing command set '#{name}'"
          blk.call(self)
        end
      end
    end

    def brew
      @brew ||= Rosh::CommandWrappers::Brew.new()
    end

    attr_accessor :using_cli
    attr_reader :env

    def initialize(ssh)
      @ssh = ssh
      @context = @ssh.hostname == 'localhost' ? :local_execute : :remote_execute
      log "Context: #{@context}"

      @env = {}
      @env = {
        hostname: @ssh.hostname,
        pwd: pwd(true).ruby_object,
        user: @ssh.options[:user],
        #path: Rosh::Environment.
      }

      @non_cli_history = []
      @using_cli = false
      @command_sets = {}

      log "Path: #{Rosh::Environment.path}"
    end

    # @return [Array<Symbol>] List of builtin_commands supported by the shell.
    def builtin_commands
      @@builtin_commands.map(&:to_s)
    end

    # @return [Array<Symbol>] List of builtin_commands supported by the shell.
    def wrapper_commands
      @@wrapper_commands.map(&:to_s)
    end

    def child_files
      Dir["#{Dir.pwd}/*"].map { |f| ::File.basename(f) }
    end

    def path_commands
      Rosh::Environment.path.map do |dir|
        Dir["#{dir}/*"].map { |f| ::File.basename(f) }
      end.flatten
    end

    # @return [Proc] The lambda to use for Readline's #completion_proc.
    def completions
      cmds = builtin_commands
      children = child_files
      all_children = children.map { |c| Dir["#{c}/**/*"] }.flatten
      hosts = Rosh::Environment.hosts.keys

      abbrevs = (cmds + children + all_children + path_commands + hosts)

      lambda { |string| abbrevs.grep ( /^#{Regexp.escape(string)}/ ) }
    end

    def exec_stored
      until @command_queue.empty? do
        result = exec(@command_queue.shift)
        yield result if block_given?
        result
      end
    end

    def reload!
      load __FILE__
      Dir[::File.dirname(__FILE__) + '/builtin_commands/*.rb'].each(&method(:load))
      Dir[::File.dirname(__FILE__) + '/command_wrappers/*.rb'].each(&method(:load))

      Rosh::CommandResult.new(true, 1)
    end

    def get_binding
      @binding ||= binding
    end
  end
end

Rosh::Shell.log_class_name = true
