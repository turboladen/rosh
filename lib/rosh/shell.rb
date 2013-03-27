require 'log_switch'
require_relative 'commands'


class Rosh
  class Shell
    extend LogSwitch
    include LogSwitch::Mixin
    include Rosh::Commands

    def initialize
      @pwd = Dir.pwd
      @exit_status = nil
      @last_exception = nil
    end

    # @return [Array<Symbol>] List of commands supported by the shell.
    def commands
      Rosh::Commands.instance_methods
    end

    # @return [Proc] The lambda to use for Readline's #completion_proc.
    def completions
      cmds = commands.map(&:to_s)
      children = Dir["#{@pwd}/*"].map { |f| ::File.basename(f) }
      all_children = children.map { |c| Dir["#{c}/**/*"] }.flatten

      abbrevs = (cmds + children + all_children)

      lambda { |string| abbrevs.grep ( /^#{Regexp.escape(string)}/ ) }
    end

    def process_command(argv)
      command, args = argv.split ' ', 2

      log "command: #{command}"
      log "args: #{args}"

      case command
      when '_?'
        return _?
      when '_!'
        return _!
      end

      @exit_status, result = begin
        if commands.include? command.to_sym
          if args && !args.empty?
            self.send(command.to_sym, args)
          else
            self.send(command.to_sym)
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
      load ::File.expand_path(::File.dirname(__FILE__) + '/commands.rb')

      [0, true]
    end

    private

    def get_binding
      @binding ||= binding
    end
  end
end
