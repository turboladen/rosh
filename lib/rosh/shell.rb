require 'abbrev'
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
    end

    # @return [Array<Symbol>] List of commands supported by the shell.
    def commands
      Rosh::Commands.instance_methods
    end

    # @return [Hash] Abbreviations to use for command completion.
    def command_abbrevs
      hash = commands.map(&:to_s).abbrev

      children = Dir["#{@pwd}/*"].map { |f| ::File.basename(f) }
      hash.merge! children.abbrev

      all_children = children.map { |c| Dir["#{c}/**/*"] }.flatten
      hash.merge! all_children.abbrev

      hash
    end

    def process_command(argv)
      command, args = argv.split ' ', 2

      log "command: #{command}"
      log "args: #{args}"
      if command == '_?'
        $stdout.puts _?
        return
      end

      @exit_status, result = if commands.include? command.to_sym
        if args && !args.empty?
          self.send(command.to_sym, args)
        else
          self.send(command.to_sym)
        end
      else
        begin
          $stdout.puts "Running Ruby: #{argv}"
          self.ruby(argv)
        rescue StandardError => ex
          [1, ex.message.red]
        end
      end

      result
    end

    def _?
      @exit_status
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
