require 'etc'
require 'socket'
require 'log_switch'
require_relative 'host/attributes'
Dir[File.dirname(__FILE__) + '/host/shells/*.rb'].each(&method(:require))
require_relative 'host/file_system'
Dir[File.dirname(__FILE__) + '/host/service_managers/*.rb'].each(&method(:require))
require_relative 'host/package_manager'
require_relative 'host/group_manager'
require_relative 'host/user_manager'


class Rosh
  class Host
    extend LogSwitch
    include LogSwitch::Mixin
    include Host::Attributes

    attr_reader :name
    attr_reader :shell
    attr_reader :user
    attr_reader :package_manager

    def initialize(hostname, host_label=nil, **ssh_options)
      @name = hostname
      @host_label = host_label || @name
      @user = ssh_options[:user] || Etc.getlogin

      @shell = if local?
        Rosh::Host::Shells::Local.new
      else
        Rosh::Host::Shells::Remote.new(@host_label, ssh_options)
      end
    end

    def set(**ssh_options)
      @shell.set(ssh_options)
    end

    def fs
      return @fs if @fs

      @fs = if local?
        Rosh::Host::FileSystem.new(@shell, false)
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
      return @user_manager if @user_manager

      @user_manager = case operating_system
      when :darwin
        Rosh::Host::UserManager.new(:open_directory, @shell)
      end
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
      @name == 'localhost'
    end
  end
end
