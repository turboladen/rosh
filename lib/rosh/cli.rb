require 'etc'
require 'ripper'
require 'readline'
require 'log_switch'
require 'irb/completion'
require 'colorize'
require_relative 'shell'



class Rosh
  class CLI
    extend LogSwitch

    include Readline
    include LogSwitch::Mixin

    Readline.completion_append_character = ' '

    def self.run
      new.run
    end

    def initialize
      @shell = Rosh::Shell.new
    end

    def new_prompt(pwd)
      prompt = '['.blue
      prompt << "#{Etc.getlogin}@#{pwd.split('/').last}".red
      prompt << ']'.blue
      prompt << '$'.red
      prompt << ' '

      prompt
    end

    def run

      loop do
        prompt = new_prompt(@shell.pwd)
        Readline.completion_proc = -> string { @shell.command_abbrevs[string] }
        argv = readline(prompt, true)

        sexp = Ripper.sexp argv
        ruby_prompt(argv) if sexp.nil?

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

    def ruby_prompt(first_statement)
      i = 1
      code = first_statement

      loop do
        prompt = "ruby[#{i}] >>".red + ' '
        code << "\n" + readline(prompt, false)
        break if Ripper.sexp code
        i += 1
      end
    end
  end
end
