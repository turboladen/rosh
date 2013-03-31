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
  end
end
