require 'etc'
require 'socket'
require 'log_switch'
require_relative 'host/attributes'
require_relative 'host/local_shell'
require_relative 'host/local_file_system'
require_relative 'host/remote_shell'
require_relative 'host/remote_file_system'
require_relative 'host/service_manager'
require_relative 'host/group_manager'
require_relative 'host/package_manager'


class Rosh
  class Host
    extend LogSwitch
    include LogSwitch::Mixin
    include Host::Attributes

    attr_reader :hostname
    attr_reader :shell
    attr_reader :user

    def initialize(hostname, **ssh_options)
      @hostname = hostname
      @user = ssh_options[:user] || Etc.getlogin

      @shell = if local?
        Rosh::Host::LocalShell.new
      else
        Rosh::Host::RemoteShell.new(@hostname, ssh_options)
      end
    end

    def set(**ssh_options)
      @shell.set(ssh_options)
    end

    def fs
      return @fs if @fs

      @fs = if local?
        Rosh::Host::LocalFileSystem.new
      else
        Rosh::Host::RemoteFileSystem.new(@shell)
      end
    end

    def services
      @service_manager ||= Rosh::Host::ServiceManager.new(self)
    end

    def users
      @user_manager ||= Rosh::Host::UserManager.new(self)
    end

    def groups
      @group_manager ||= Rosh::Host::GroupManager.new(self)
    end

    def packages
      @package_manager ||= Rosh::Host::PackageManager.new(self)
    end

    def local?
      @hostname == 'localhost'
    end
  end
end
