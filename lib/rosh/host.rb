require 'etc'
require 'socket'
require 'log_switch'

require_relative 'observer'
require_relative 'observable'
require_relative 'shell'
require_relative 'host/attributes'
require_relative 'file_system'
require_relative 'service_manager'
require_relative 'package_manager'
require_relative 'process_manager'
require_relative 'user_manager'

require_relative 'kernel_refinements'
require_relative 'string_refinements'


class Rosh
  class Host
    extend LogSwitch
    include LogSwitch::Mixin
    include Host::Attributes
    include Rosh::Observer
    include Rosh::Observable

    attr_reader :name
    attr_reader :shell
    attr_reader :user

    def initialize(host_name, **ssh_options)
      @name = host_name
      @user = ssh_options[:user] || Etc.getlogin
      @shell = Rosh::Shell.new(@name, ssh_options)
    end

    def set(**ssh_options)
      @shell.set(ssh_options)
    end

    # Access to the FileSystem for the Host's OS type.
    #
    # @return [Rosh::FileSystem]
    # @see Rosh::FileSystem
    def fs
      return @file_system if @file_system

      @file_system = Rosh::FileSystem.new(@name)
      @file_system.add_observer(self)

      @file_system
    end

    # Access to the UserManager for the Host's OS type.
    #
    # @return [Rosh::UserManager]
    # @see Rosh::UserManager
    def users
      return @user_manager if @user_manager

      @user_manager = Rosh::UserManager.new(@name)
      @user_manager.add_observer(self)

      @user_manager
    end

    # Access to the PackageManager for the Host's OS type.
    #
    # @return [Rosh::PackageManager]
    # @see Rosh::PackageManager
    def packages
      return @package_manager if @package_manager

      @package_manager = Rosh::PackageManager.new(@name)
      @package_manager.add_observer(self)

      @package_manager
    end

    # Access to the ProcessManager for the Host's OS type.
    #
    # @return [Rosh::ProcessManager]
    # @see Rosh::ProcessManager
    def processes
      return @process_manager if @process_manager

      @process_manager = Rosh::ProcessManager.new(@name)
      @process_manager.add_observer(self)

      @process_manager
    end

    # Access to the ServiceManager for the Host's OS type.
    #
    # @return [Rosh::ServiceManager]
    # @see Rosh::ServiceManager
    def services
      return @service_manager if @service_manager

      @service_manager = Rosh::ServiceManager.new(@name)
      @service_manager.add_observer(self)

      @service_manager
    end

    # @param [String] user
    # @param [Proc] block The code to execute in the sudo context.
    def su(user=nil, &block)
      @shell.su(user, &block)
    end

    # @return [Boolean]
    def local?
      @name == 'localhost'
    end
  end
end
