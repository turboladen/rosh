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
      @original = {
        pwd: ENV['PWD'],
        shell: ENV['SHELL']
      }

      at_exit do
        ENV['PWD'] = @original[:pwd]
        ENV['SHELL'] = @original[:shell]
      end

      ENV['SHELL'] = ::File.expand_path($0)

      Rosh::Environment.current_hostname = 'localhost'
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

        next if checking_exit_status(argv)
        next if checking_last_result(argv)
        next if changing_host(argv)

        if multiline_ruby?(argv)
          argv = ruby_prompt(argv)
          log "Multi-line Ruby; argv is now: #{argv}"
        else
          log 'Not multiline Ruby'
        end

        result = execute(argv)
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
        if @host.shell.builtin_commands.include? command
          if !args.empty?
            @host.shell.send(command.to_sym, *args)
          else
            @host.shell.send(command.to_sym)
          end
        elsif @host.shell.path_commands.include? command
          @host.shell.exec(argv)
        elsif @host.shell.path_commands.include? command.split('/').last
          @host.shell.exec(argv)
        else
          $stdout.puts "Running Ruby: #{argv}"
          @host.shell.ruby(argv)
        end
      rescue StandardError => ex
        ::Rosh::CommandResult.new(ex, 1)
      end

      result
    end

    def new_prompt(pwd)
      user_and_host = '['.blue
      user_and_host << "#{Etc.getlogin}@#{@host.hostname}:#{pwd.split('/').last}".red
      user_and_host << ']'.blue

      _, width = Readline.get_screen_size
      git = %x[git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/']

      prompt = user_and_host

      unless git.empty?
        prompt << ("%#{width + 42 - user_and_host.size}s".yellow % "[git(#{git.strip})]")
      end

      prompt << '$ '.red

      prompt
    end

    def print_result(result)
      if [Array, Hash, Struct, Exception].any? { |klass| result.ruby_object.kind_of? klass }
        log 'Printing a pretty object'
        ap result.ruby_object
      else
        if result.exit_status && !result.exit_status.zero?
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

    private

    def checking_exit_status(argv)
      if argv == '_?'
        $stdout.puts @last_result.exit_status

        return @last_result.exit_status
      end

      false
    end

    def checking_last_result(argv)
      if argv == '_!'
        result = if @last_result && @last_result.ruby_object.kind_of?(Exception)
          @last_result.ruby_object
        else
          nil
        end

        $stdout.puts result

        return result || true
      end

      false
    end

    def changing_host(argv)
      if argv.match /^\s*ch\s/
        ch(argv.shellsplit.last)

        return true
      end

      false
    end

    def ch(hostname)
      new_host = Rosh::Environment.hosts[hostname.strip]

      if new_host.nil?
        log "No host defined for '#{hostname}'"
        Rosh::CommandResult.new(new_host, 1)
      else
        log "Changed to host '#{hostname}'"
        @host = new_host
        Rosh::CommandResult.new(new_host, 0)
      end
    end

  end
end

Rosh::CLI.log_class_name = true
