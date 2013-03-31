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
      @host.shell.using_cli = true
      @last_result = nil
    end

    def run
      loop do
        prompt = new_prompt(Dir.pwd)
        Readline.completion_proc = @host.shell.completions

        argv = readline(prompt, true)
        next if argv.empty?
        log "Just read input: #{argv}"

        if argv == '_?'
          $stdout.puts @last_result.status
          next
        elsif argv == '_!'
          result = if @last_result && @last_result.ruby_object.kind_of?(Exception)
            @last_result.ruby_object
          else
            nil
          end

          $stdout.puts result
          result
          next
        else
          log 'Not a global shell var'
        end

        result = if argv.match /^\s*ch\s/
          ch(argv.shellsplit.last)
        else
          if multiline_ruby?(argv)
            argv = ruby_prompt(argv)
            log "Multi-line Ruby; argv is now: #{argv}"
          else
            log 'Not multiline Ruby'
          end

          execute(argv)
        end

        @last_result = result
        print_result(result)

        result
      end
    end

    def execute(argv)
      new_argv = argv.dup.shellsplit
      command = new_argv.shift
      args = new_argv

      log "command: #{command}"
      log "new argv: #{new_argv}"

      result = begin
        if @host.shell.builtin_commands.include? command.to_sym
          if !args.empty?
            @host.shell.send(command.to_sym, *args)
          else
            @host.shell.send(command.to_sym)
          end
        else
          $stdout.puts "Running Ruby: #{argv}"
          @host.shell.ruby(argv, @host.shell.get_binding)
        end
      rescue StandardError => ex
        ::Rosh::CommandResult.new(ex, 1)
      end

      result
    end

    def new_prompt(pwd)
      prompt = '['.blue
      prompt << "#{Etc.getlogin}@#{@host.hostname}:#{pwd.split('/').last}".red
      prompt << ']'.blue
      prompt << '$'.red
      prompt << ' '

      prompt
    end

    def print_result(result)
      if [Array, Hash, Struct, Exception].any? { |klass| result.ruby_object.kind_of? klass }
        log 'Printing a pretty object'
        ap result.ruby_object
      else
        if @_exit_status && !@_exit_status.zero?
          $stderr.puts "  #{result.ruby_object}".light_red
        else
          $stdout.puts "  #{result.ruby_object}".light_blue
        end
      end
    end

    def multiline_ruby?(argv)
      sexp = Ripper.sexp argv

      sexp.nil?
    end

    def ch(hostname)
      new_host = Rosh::Environment.hosts[hostname.strip]

      if new_host.nil?
        log "No host defined for #{hostname}"
        @_exit_status = 1
      else
        log "Changed to host #{hostname}"
        @_exit_status = 0
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

Rosh::CLI.log_class_name = true
