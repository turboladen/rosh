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

require_relative 'kernel_refinements'
require_relative 'string_refinements'


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
        Rosh::Host::Shells::Remote.new(@name, ssh_options)
      end
    end

    def set(**ssh_options)
      @shell.set(ssh_options)
    end

    def fs
      @fs ||= Rosh::Host::FileSystem.new(@host_label)
    end

    # Access to the PackageManager for the Host's OS type.
    #
    # @return [Rosh::Host::PackageManager]
    # @see Rosh::Host::PackageManager
    def packages
      return @package_manager if @package_manager

      @package_manager = case operating_system
      when :darwin
        Rosh::Host::PackageManager.new(:brew, :brew, @host_label)
      when :linux
        case distribution
        when :ubuntu
          Rosh::Host::PackageManager.new(:apt, :dpkg, @host_label)
        when :centos
          Rosh::Host::PackageManager.new(:yum, :rpm, @host_label)
        end
      end
    end

    def services
      return @service_manager if @service_manager

      @service_manager = case operating_system
      when :darwin
        Rosh::Host::ServiceManagers::LaunchCTL.new(@host_label)
      when :linux
        Rosh::Host::ServiceManagers::Init.new(:linux, @host_label)
      when :freebsd
        Rosh::Host::ServiceManagers::Init.new(:freebsd, @host_label)
      end
    end

    def users
      return @user_manager if @user_manager

      @user_manager = case operating_system
      when :darwin
        Rosh::Host::UserManager.new(:open_directory, @host_label)
      end
    end

    def groups
      @group_manager ||= Rosh::Host::GroupManager.new(self)
    end

    def local?
      @name == 'localhost'
    end
  end
end
