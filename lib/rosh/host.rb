require 'etc'
require 'socket'
require 'log_switch'
require_relative 'host/attributes'
Dir[File.dirname(__FILE__) + '/host/shells/*.rb'].each(&method(:require))
require_relative 'host/file_system'
Dir[File.dirname(__FILE__) + '/host/service_managers/*.rb'].each(&method(:require))
require_relative 'host/package_manager'
require_relative 'host/group_manager'


class Rosh
  class Host
    extend LogSwitch
    include LogSwitch::Mixin
    include Host::Attributes

    attr_reader :hostname
    attr_reader :shell
    attr_reader :user
    attr_reader :package_manager

    def initialize(hostname,  **ssh_options)
      @hostname = hostname
      @user = ssh_options[:user] || Etc.getlogin

      @shell = if local?
        Rosh::Host::Shells::Local.new
      else
        Rosh::Host::Shells::Remote.new(@hostname, ssh_options)
      end
    end

    def set(**ssh_options)
      @shell.set(ssh_options)
    end

    def fs
      return @fs if @fs

      @fs = if local?
        Rosh::Host::FileSystem.new
      else
        Rosh::Host::FileSystem.new(@shell)
      end
    end

    def services
      return @service_manager if @service_manager

      @service_manager = case operating_system
      when :darwin
        Rosh::Host::ServiceManagers::LaunchCTL.new(@shell)
      when :linux
        Rosh::Host::ServiceManagers::Init.new(@shell, :linux)
      when :freebsd
        Rosh::Host::ServiceManagers::Init.new(@shell, :freebsd)
      end
    end

    def users
      @user_manager ||= Rosh::Host::UserManager.new(self)
    end

    def groups
      @group_manager ||= Rosh::Host::GroupManager.new(self)
    end

    # Access to the PackageManager for the Host's OS type.
    #
    # @return [Rosh::Host::PackageManager]
    # @see Rosh::Host::PackageManager
    def packages
      return @package_manager if @package_manager

      @package_manager = case operating_system
      when :darwin
        Rosh::Host::PackageManager.new(:brew, :brew, @shell)
      when :linux
        case distribution
        when :ubuntu
          Rosh::Host::PackageManager.new(:apt, :dpkg, @shell)
        when :centos
          Rosh::Host::PackageManager.new(:yum, :rpm, @shell)
        end
      end
    end

    def local?
      @hostname == 'localhost'
    end
  end
end
