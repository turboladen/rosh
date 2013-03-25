require 'shellwords'
require 'readline'
require 'colorize'
require 'log_switch'
require_relative 'shell'


class Rosh
  class CLI
    include Readline
    extend LogSwitch
    include LogSwitch::Mixin

    Readline.completion_append_character = ' '


    def self.run
      new.run
    end

    def initialize
      @shell = Rosh::Shell.new
    end

    def run
      loop do
        prompt = "[#{@shell.pwd}]$".red.on_white + ' '
        argv = readline(prompt, true)
        Readline.completion_proc = -> string { @shell.command_abbrevs[string] }

        command, args = argv.split ' ', 2

        log "command: #{command}"
        log "args: #{args}"
        log "shell methods: #{@shell.commands}"

        result = if @shell.commands.include? command.to_sym
          if args && !args.empty?
            @shell.send(command.to_sym, args)
          else
            @shell.send(command.to_sym)
          end
        else
          begin
            puts "Running Ruby: #{argv}"
            @shell.ruby(argv)
          rescue StandardError => ex
            puts "  #{ex.message}".red
            puts "  #{@shell.history.last}".yellow
            false
          end
        end

        puts "  #{result}".light_blue

        result
      end
    end
  end
end
