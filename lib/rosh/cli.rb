require 'etc'
require 'ripper'
require 'readline'
require 'irb/completion'

require 'awesome_print'
require 'log_switch'
require 'colorize'

require_relative 'shell'


class Rosh
  class CLI
    extend LogSwitch

    include Readline
    include LogSwitch::Mixin

    Readline.completion_append_character = ' '

    def self.run
      ::Rosh::CLI.log = false
      new.run
    end

    def initialize
      @shell = Rosh::Shell.new
    end

    def new_prompt(pwd)
      prompt = '['.blue
      prompt << "#{Etc.getlogin}@#{pwd[1].split('/').last}".red
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
        next if argv.empty?

        argv = ruby_prompt(argv) if multiline_ruby?(argv)
        result = @shell.process_command(argv)
        print_result(result)

        result
      end
    end

    def print_result(result)
      if [Array, Hash, Struct].any? { |klass| result.kind_of? klass }
        ap result
      else
        if @shell._? && !@shell._?.zero?
          $stderr.puts "  #{result}".light_red
        else
          $stdout.puts "  #{result}".light_blue
        end
      end
    end

    def multiline_ruby?(argv)
      sexp = Ripper.sexp argv

      sexp.nil?
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

      code
    end
  end
end
