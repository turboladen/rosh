require 'log_switch'
require_relative 'command_result'
Dir[File.dirname(__FILE__) + '/builtin_commands/*.rb'].each(&method(:require))


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

    @@builtin_commands = []

    Rosh::BuiltinCommands.constants.each do |action_class|
      meth_name = action_class.to_s.downcase.to_sym
      @@builtin_commands << meth_name

      define_method(meth_name) do |*args, **options, &block|
        klass = Rosh::BuiltinCommands.const_get(action_class)

        unless @using_cli
          cmd = "#{meth_name} #{args.join(' ')}".strip
          @non_cli_history.push(cmd)
        end

        if meth_name == :history
          history_array = @using_cli ? Readline::HISTORY.to_a : @non_cli_history
          klass.new(history_array, &block).execute(@context).call(@ssh)
        elsif options.empty? && args.empty?
          klass.new(&block).execute(@context).call(@ssh)
        elsif options.empty?
          klass.new(*args, &block).execute(@context).call(@ssh)
        elsif args.empty?
          klass.new(**options, &block).execute(@context).call(@ssh)
        else
          klass.new(*args, **options, &block).execute(@context).call(@ssh)
        end
      end
    end

    attr_accessor :using_cli

    def initialize(ssh)
      @commands = []
      @ssh = ssh
      @context = @ssh.hostname == 'localhost' ? :local : :remote
      @using_cli = false
      @non_cli_history = []
    end

    # @return [Array<Symbol>] List of builtin_commands supported by the shell.
    def builtin_commands
      @@builtin_commands
    end

    # @return [Proc] The lambda to use for Readline's #completion_proc.
    def completions
      cmds = builtin_commands.map(&:to_s)
      children = Dir["#{Dir.pwd}/*"].map { |f| ::File.basename(f) }
      all_children = children.map { |c| Dir["#{c}/**/*"] }.flatten

      abbrevs = (cmds + children + all_children)

      lambda { |string| abbrevs.grep ( /^#{Regexp.escape(string)}/ ) }
    end

    def add_command(cmd)
      #argv = cmd.shellwords

      klass_name = Rosh::BuiltinCommands.constants.find do |action_class|
        cmd == action_class.to_s.downcase
      end
      klass = Rosh::BuiltinCommands.const_get(klass_name)
      klass.new(*args, **options, &block)

      @commands << cmd
    end

    def run_all
      until @commands.empty? do
        execute @commands.shift
      end
    end

    def reload!
      load __FILE__
      load ::File.expand_path(::File.dirname(__FILE__) + '/builtin_commands.rb')

      [0, true]
    end

    def get_binding
      @binding ||= binding
    end
  end
end

Rosh::Shell.log_class_name = true
