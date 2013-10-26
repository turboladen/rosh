require 'etc'
require 'socket'
require 'log_switch'

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

    def fs
      @file_system ||= Rosh::FileSystem.new(@name)
    end

    def users
      @user_manager ||= Rosh::UserManager.new(@name)
    end

    # Access to the PackageManager for the Host's OS type.
    #
    # @return [Rosh::PackageManager]
    # @see Rosh::PackageManager
    def packages
      @package_manager ||= Rosh::PackageManager.new(@name)
    end

    def processes
      @process_manager ||= Rosh::ProcessManager.new(@name)
    end

    # Access to the ServiceManager for the Host's OS type.
    #
    # @return [Rosh::ServiceManager]
    # @see Rosh::ServiceManager
    def services
      @service_manager ||= Rosh::ServiceManager.new(@name)
    end

    def su(user=nil, &block)
      @shell.su(user, &block)
    end

    def local?
      @name == 'localhost'
    end
  end
end
