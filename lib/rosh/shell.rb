require 'log_switch'
require_relative 'environment'
require_relative 'command_result'
#require_relative 'builtin_commands'
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
    include Rosh::BuiltinCommands

    @@builtin_commands = []

    Rosh::BuiltinCommands.constants.each do |action_class|
      meth_name = action_class.to_s.downcase.to_sym
      @@builtin_commands << meth_name

      define_method(meth_name) do |*args, **options, &block|
        klass = Rosh::BuiltinCommands.const_get(action_class)

        if options.empty? && args.empty?
          klass.new(&block).execute(@context).call(@ssh)
        elsif options.empty?
          klass.new(*args, &block).execute(@context).call(@ssh)
        elsif args.empty?
          klass.new(*args, &block).execute(@context).call(@ssh)
        else
          klass.new(*args, **options, &block).execute(@context).call(@ssh)
        end
      end
    end

    def initialize(ssh)
      @exit_status = nil
      @last_exception = nil
      @commands = []
      @ssh = ssh
      @context = @ssh.hostname == 'localhost' ? :local : :remote
    end

    # @return [Array<Symbol>] List of builtin_commands supported by the shell.
    def builtin_commands
      #Rosh::BuiltinCommands.instance_methods
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

    def execute(argv)
      command = argv.shift
      args = argv

      log "command: #{command}"
      log "command class: #{command.class}"

      case command
      when '_?'
        return _?
      when '_!'
        return _!
      end

      result = begin
        if builtin_commands.include? command.to_sym
          if !args.empty?
            self.send(command.to_sym, *args)
          else
            self.send(command.to_sym)
          end
        else
          $stdout.puts "Running Ruby: #{argv}"
          self.ruby(argv)
        end
      rescue StandardError => ex
        @last_exception = ex
        ::Rosh::CommandResult.new(ex, 1)
      end

      @exit_status = result.status
      @ssh_result = result.ssh_result

      #@last_exception = result if result.kind_of? Exception

      result
    end

    def _?
      @exit_status
    end

    def _!
      @last_exception
    end

    def reload!
      load __FILE__
      load ::File.expand_path(::File.dirname(__FILE__) + '/builtin_commands.rb')

      [0, true]
    end

    private

    def get_binding
      @binding ||= binding
    end
  end
end
