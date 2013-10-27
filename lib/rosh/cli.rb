require 'etc'
require 'ripper'
require 'readline'
require 'shellwords'

require 'log_switch'
require 'colorize'

require_relative '../rosh'
require_relative 'shell/command_result'
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

      if Rosh.load_config
        instance_eval Rosh.config
      else
        Rosh.add_host 'localhost'
      end

      localhost = if Rosh.hosts['localhost']
        Rosh.hosts['localhost']
      elsif Rosh.hosts[:localhost]
        Rosh.hosts[:localhost]
      else
        Rosh.hosts.values.find { |host| host.name == 'localhost' }
      end

      @current_host ||= localhost
    end

    # Starts the Readline loop for accepting input.  Each iteration through the
    # loop returns the resulting object of the Ruby code that was executed.
    #
    # @todo Allow accepting named params to commands (i.e. `ps pid: 234`)
    def run
      stty_save = `stty -g`.chomp
      trap('INT') { system('stty', stty_save); exit }

      loop do
        log "Current host is: #{@current_host.name}"
        prompt = ENV['PROMPT'] || new_prompt

        Readline.completion_proc = Rosh::Completion.build do
          [
            @current_host.shell.public_methods(false).map(&:to_s) |
            @current_host.shell.system_commands.map(&:to_s),
            Rosh.hosts.keys,
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

        execute(argv)
      end
    end

    # @param [String] argv The command given at the prompt.
    # @return [Rosh::Shell::CommandResult]
    def execute(argv)
      new_argv = argv.dup.shellsplit
      command = new_argv.shift.to_sym
      args = new_argv

      log "command: #{command}"
      log "new argv: #{new_argv}"

      if %i[ch].include? command
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
      user_and_host << "@#{@current_host.name}".red
      user_and_host << ":#{@current_host.shell._env[:pwd].split('/').last}".red
      user_and_host << ']'.blue

=begin
      _, width = Readline.get_screen_size
      git = %x[git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/']
=end

      prompt = user_and_host

=begin
      unless git.empty?
        prompt << ("%#{width + 70 - user_and_host.size}s".yellow % "[git(#{git.strip})]")
      end
=end

      prompt << '$ '.red

      prompt
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

    def ch(host_name)
      new_host = Rosh.hosts[host_name]

      if new_host.nil?
        log "No host defined for '#{host_name}'"
        Rosh::Shell::CommandResult.new(new_host, 1)
      else
        log "Changed to host '#{host_name}'"
        @current_host = new_host
        Rosh::Shell::CommandResult.new(new_host, 0)
      end
    end
  end
end

Rosh::CLI.log_class_name = true
