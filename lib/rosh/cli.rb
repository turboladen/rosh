require 'etc'
require 'ripper'
require 'readline'
require 'shellwords'

require 'awesome_print'
require 'log_switch'
require 'colorize'

require_relative 'host'


class Rosh
  class CLI
    extend LogSwitch

    include Shellwords
    include Readline
    include LogSwitch::Mixin

    Readline.completion_append_character = ' '

    def self.run
      #::Rosh::CLI.log = false
      new.run
    end

    def initialize
      @host = Rosh::Host.new 'localhost'
    end

    def new_prompt(pwd)
      prompt = '['.blue
      prompt << "#{Etc.getlogin}@#{@host.hostname}:#{pwd.ruby_object.split('/').last}".red
      prompt << ']'.blue
      prompt << '$'.red
      prompt << ' '

      prompt
    end

    def run
      loop do
        prompt = new_prompt(@host.shell.pwd)
        Readline.completion_proc = @host.shell.completions

        argv = readline(prompt, true)

        next if argv.empty?

        result = if argv.match /\s*ch\s/
          ch(argv.shellsplit.last)
        else
          argv = ruby_prompt(argv) if multiline_ruby?(argv)
          @host.shell.execute(argv.shellsplit)
        end

        print_result(result)

        result
      end
    end

    def print_result(result)
      if [Array, Hash, Struct].any? { |klass| result.ruby_object.kind_of? klass }
        ap result.ruby_object
      else
        if @host.shell._? && !@host.shell._?.zero?
          $stderr.puts "  #{result.ruby_object}".light_red
        else
          $stdout.puts "  #{result.ruby_object}".light_blue
        end
      end
    end

    def multiline_ruby?(argv)
      sexp = Ripper.sexp argv
      lex = Ripper.lex argv

      sexp.nil?
    end

    def ch(hostname)
      new_host = Rosh::Environment.hosts[hostname.strip]

      if new_host.nil?
        puts "No host defined for #{hostname}"
        @host.shell.instance_variable_set(:@exit_status, 1)
      else
        puts "Changed to host #{hostname}"
        @host = new_host
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

      code
    end
  end
end
