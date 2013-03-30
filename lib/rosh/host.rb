require 'colorize'
require_relative 'ssh'
require_relative 'environment'
require_relative 'shell'
require_relative 'host/environment'
require_relative 'host/file_system'


class Rosh

  # An Host runs Rosh::Actions on a remote host.
  #
  #   host = Rosh::Host.new 'my_box'
  #
  #   host.brew formula: 'rbenv'
  #   host.subversion repository: 'http://entmenu.googlecode.com/svn/trunk/',
  #     destination: '/tmp/entmenu'
  #   host.directory path: '/tmp/entmenu', state: :absent
  #   host.shell command: %[/usr/bin/env python -V]
  #   host.directory path: '/tmp/steve'
  #   host.directory path: '/tmp/steve', state: :absent
  #   host.script source_file: 'script_test.rb', args: '--first-arg'
  #
  #   host.action!
  #
  class Host
    include Rosh::BuiltinCommands
    include LogSwitch::Mixin

    attr_reader :hostname

    def initialize(hostname, **ssh_options)
      @hostname = hostname
      @commands = []
      @ssh_options = ssh_options

      log "Initialized for host: #{@hostname}"

      unless Rosh::Environment.hosts[hostname]
        Rosh::Environment.hosts[hostname] = self
      end
    end

    def ssh
      @ssh ||= Rosh::SSH.new(@hostname, @ssh_options)
    end

    def shell
      @shell ||= Rosh::Shell.new(ssh)
    end

    def env
      @env ||= Rosh::Host::Environment.new(@hostname)
    end

    def fs
      @fs ||= Rosh::Host::FileSystem.new(@hostname)
    end

=begin
    def action!
      log 'Starting action...'
      log "...hostname: #{@hostname}"
      log "...ssh options: #{@ssh_options}"
      log "...actions: #{@commands}"
      puts "Executing action on host '#{@hostname}'".blue

      start_time = Time.now

      @commands.each do |cmd|
        run_action(cmd)
      end

      puts "Rosh finished performing\nTotal Duration: #{Time.now - start_time}".green
    end

    def run_action(action)
      puts "Running #{action.class} command: '#{action.command}'".blue
      result = action.perform(@hostname)
      raise 'Action result status was nil' if result.status.nil?

      if result.failed?
        if action.fail_block
          actions_before = @commands.size
          action.fail_block.call
          new_action_count = @commands.size - actions_before
          puts "new actikon count: #{new_action_count}".light_green
          new_actions = @commands.pop(new_action_count)

          new_actions.each do |command|
            run_action(command)
          end
        else
          plan_failure(result)
        end
      elsif result.no_change?
        puts "Rosh finished [NO CHANGE]: '#{action.command}'".yellow
      elsif result.updated?
        puts "Rosh finished [UPDATED]: '#{action.command}'".green
      else
        puts "WTF? status: #{result.status}".red
        puts "WTF? status class: #{result.status.class}".red
      end
    end

    def play_part(part_class, **options)
      part_class.play(self, **options)
    end

    def drama_failure(result)
      log "Failure: #{result}"

      if result.success
        error = <<-ERROR
*** Rosh Error! ***
* Exception: #{result.exception}
* Exception class: #{result.exception.class}
* Plan duration: #{result.finished_at - result.started_at || 0}
* SCP source: #{result.ssh_options[:scp_src]}
* SCP destination: #{result.ssh_options[:scp_dst]}
* STDERR: #{result.stderr}
        ERROR

        abort(error.red)
      else
        raise result.exception
      end
    end

    def plan_failure(result)
      log "Plan Failure: #{result}"

      error = <<-ERROR
*** Rosh Plan Failure! ***
* Plan failed: #{result.command}
* Exit code: #{result.exit_code}
* Plan Duration: #{result.finished_at - result.started_at}
* STDERR: #{result.stderr}
      ERROR

      abort(error.red)
    end
=end
  end
end
