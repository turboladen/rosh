require 'etc'
require 'socket'
require 'log_switch'
require_relative 'host/attributes'
Dir[File.dirname(__FILE__) + '/host/shells/*.rb'].each(&method(:require))
require_relative 'file_system'
require_relative 'host/package_manager'
require_relative 'host/service_manager'
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

    def initialize(host_name, **ssh_options)
      @name = host_name
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
      @fs ||= Rosh::FileSystem.new(@name)
    end

    # Access to the PackageManager for the Host's OS type.
    #
    # @return [Rosh::Host::PackageManager]
    # @see Rosh::Host::PackageManager
    def packages
      return @package_manager if @package_manager

      @package_manager = case operating_system
      when :darwin
        Rosh::Host::PackageManager.new(@name, :brew)
      when :linux
        case distribution
        when :ubuntu
          Rosh::Host::PackageManager.new(@name, :apt, :dpkg)
        when :centos
          Rosh::Host::PackageManager.new(@name, :yum)
        end
      end
    end

    def services
      return @service_manager if @service_manager

      @service_manager = case operating_system
      when :darwin
        Rosh::Host::ServiceManager.new(@name, :launch_ctl)
      when :linux
        Rosh::Host::ServiceManager.new(@name, :init)
      when :freebsd
        Rosh::Host::ServiceManager.new(@name, :init)
      end
    end

    def users
      return @user_manager if @user_manager

      @user_manager = case operating_system
      when :darwin
        Rosh::Host::UserManager.new(:open_directory, @name)
      end
    end

    def groups
      return @group_manager if @group_manager

      @group_manager = case operating_system
      when :darwin
        Rosh::Host::GroupManager.new(:open_directory, @name)
      end
    end

    def local?
      @name == 'localhost'
    end
  end
end
