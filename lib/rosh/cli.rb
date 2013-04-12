require 'etc'
require 'ripper'
require 'readline'
require 'shellwords'

require 'awesome_print'
require 'log_switch'
require 'colorize'

require_relative '../rosh'
require_relative 'command_result'
require_relative 'completion'


class Rosh
  class CLI
    extend LogSwitch

    include Shellwords
    include Readline
    include LogSwitch::Mixin

    # Convenience method for calling Rosh::CLI.new.run.
    def self.run
      new.run
    end

    def initialize
      ENV['SHELL'] = ::File.expand_path($0)

      @rosh = Rosh.new
      @rosh.add_host 'localhost'
      @current_host = @rosh.hosts['localhost']
      @last_result = nil
    end

    # Starts the Readline loop for accepting input.  Each iteration through the
    # loop returns the resulting object of the Ruby code that was executed.
    def run
      stty_save = `stty -g`.chomp
      trap('INT') { system('stty', stty_save); exit }

      loop do
        log "Current host is: #{@current_host.hostname}"
        prompt = ENV['PROMPT'] || new_prompt

        Readline.completion_proc = Rosh::Completion.build do
          [
            @current_host.shell.public_methods(false).map(&:to_s) |
            @current_host.shell.system_commands.map(&:to_s),
            @rosh.hosts.keys,
            @current_host.shell.workspace.send(:binding)
          ]
        end

        argv = readline(prompt, true)
        next if argv.empty?

        log "Read input: #{argv}"

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

      if %i[ch history].include? command
        self.send(command, *args)
      elsif @current_host.shell.public_methods(false).include? command
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
      user_and_host << ":#{@current_host.shell.env[:pwd].split('/').last}".red
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
      log "Resulting Ruby object is a '#{result.class}'"

      if [Array, Hash, Struct].any? { |klass| result.kind_of? klass }
        ap result
      elsif [Rosh::Host::LocalFileSystemObject, Rosh::Host::RemoteFileSystemObject, Dir].any? do |klass|
        result.kind_of? klass
      end
        puts result.inspect.light_blue
      elsif result.kind_of? Exception
        puts result.message.red
        result.backtrace.each { |b| puts b.red }
      else
        if !@current_host.shell.last_exit_status.zero?
          $stderr.puts "  #{result}".light_red
        else
          $stdout.puts "  #{result}".light_blue
        end
      end
    end

    def multiline_ruby?(argv)
      found = argv.scan(/(\S*\.\.\S*)/).flatten

      unless found.empty?
        argv.sub!(found.first, %['#{found.first}'])
      end

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

    def ch(hostname)
      new_host = @rosh.hosts[hostname]

      if new_host.nil?
        log "No host defined for '#{hostname}'"
        Rosh::CommandResult.new(new_host, 1)
      else
        log "Changed to host '#{hostname}'"
        @current_host = new_host
        Rosh::CommandResult.new(new_host, 0)
      end
    end

    def history
      lines = {}

      Readline::HISTORY.to_a.each_with_index do |cmd, i|
        lines[i] = cmd
      end

      Rosh::CommandResult.new(Hash[lines.sort], 0)
    end
  end
end

Rosh::CLI.log_class_name = true
Rosh::CLI.log = false
