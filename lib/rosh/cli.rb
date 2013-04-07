require 'etc'
require 'ripper'
require 'readline'
require 'shellwords'

require 'awesome_print'
require 'log_switch'
require 'colorize'

require_relative '../rosh'
require_relative 'command_result'


class Rosh
  class CLI
    extend LogSwitch

    include Shellwords
    include Readline
    include LogSwitch::Mixin

    Readline.completion_append_character = ' '

    # Convenience method for calling Rosh::CLI.new.run.
    def self.run
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

      r = Rosh.new
      r.add_host 'localhost'
      @current_host = r.hosts['localhost']
      @last_result = nil
    end

    # Starts the Readline loop for accepting input.  Each iteration through the
    # loop returns the resulting object of the Ruby code that was executed.
    def run
      loop do
        log "Current host is: #{@current_host.hostname}"
        prompt = new_prompt
        #Readline.completion_proc = @current_host.shell.completions

        argv = readline(prompt, true)
        next if argv.empty?
        log "Read input: #{argv}"

        #next if changing_host(argv)

        if multiline_ruby?(argv)
          argv = ruby_prompt(argv)
          log "Multi-line Ruby; argv is now: #{argv}"
        end

        result = execute(argv)
        @last_result = result
        print_result(result)
      end
    end

    # @param [String] argv The command given at the prompt.
    # @return [Ros::CommandResult]
    def execute(argv)
      new_argv = argv.dup.shellsplit
      command = new_argv.shift.to_sym
      args = new_argv

      log "command: #{command}"
      log "new argv: #{new_argv}"

      if @current_host.shell.public_methods(false).include? command
        if !args.empty?
          @current_host.shell.send(command, *args)
        else
          @current_host.shell.send(command)
        end
      elsif @current_host.shell.system_commands.include? command.to_s
        @current_host.shell.exec(argv)
      elsif @current_host.shell.system_commands.include? command.to_s.split('/').last
        @current_host.shell.exec(argv)
      else
        $stdout.puts "Running Ruby: #{argv}"
        @current_host.shell.ruby(argv)
      end
    end

    def new_prompt
      user_and_host = '['.blue
      user_and_host << "#{@current_host.user}".red
      user_and_host << "@#{@current_host.hostname}".red
      user_and_host << ":#{@current_host.shell.env.ruby_object[:pwd].split('/').last}".red
      user_and_host << ']'.blue

      _, width = Readline.get_screen_size
      git = %x[git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/']

      prompt = user_and_host

      unless git.empty?
        prompt << ("%#{width + 70 - user_and_host.size}s".yellow % "[git(#{git.strip})]")
      end

      prompt << '$ '.red

      prompt
    end

    def print_result(result)
      log "Result is a '#{result.class}'"
      log "Resulting Ruby object is: '#{result}'"
      log "Resulting Ruby object is a '#{result.ruby_object.class}'"

      if [Array, Hash, Struct].any? { |klass| result.ruby_object.kind_of? klass }
        ap result.ruby_object
      elsif result.ruby_object.kind_of? Exception
        puts result.ruby_object.message.red
        result.ruby_object.backtrace.each { |b| puts b.red }
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

    #---------------------------------------------------------------------------
    # Privates!
    #---------------------------------------------------------------------------
    private

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
        Rosh::Environment.current_hostname = hostname.strip
        @current_host = new_host
        Rosh::CommandResult.new(new_host, 0)
      end
    end
  end
end

Rosh::CLI.log_class_name = true
Rosh::CLI.log = true
