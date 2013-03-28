require 'log_switch'
require_relative 'builtin_commands'
require_relative 'environment'


class Rosh
  class Shell
    extend LogSwitch
    include LogSwitch::Mixin
    include Rosh::BuiltinCommands

    def initialize(ssh)
      @exit_status = nil
      @last_exception = nil
    end

    # @return [Array<Symbol>] List of builtin_commands supported by the shell.
    def builtin_commands
      Rosh::BuiltinCommands.instance_methods
    end

    # @return [Proc] The lambda to use for Readline's #completion_proc.
    def completions
      cmds = builtin_commands.map(&:to_s)
      children = Dir["#{Dir.pwd}/*"].map { |f| ::File.basename(f) }
      all_children = children.map { |c| Dir["#{c}/**/*"] }.flatten

      abbrevs = (cmds + children + all_children)

      lambda { |string| abbrevs.grep ( /^#{Regexp.escape(string)}/ ) }
    end

    def process_command(argv)
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

      @exit_status, result = begin
        if builtin_commands.include? command.to_sym
          if args && !args.empty?
            args.each_with_index { |a, i| log "arg#{i}: #{a}" }
            self.send(command.to_sym, *args).execute
          else
            log "<#{command}>"
            self.send(command.to_sym).execute
          end
        else
          $stdout.puts "Running Ruby: #{argv}"
          self.ruby(argv)
        end
      rescue StandardError => ex
        @last_exception = ex
        [1, ex]
      end

      @last_exception = result if result.kind_of? Exception

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
