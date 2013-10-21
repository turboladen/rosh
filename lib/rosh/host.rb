require 'etc'
require 'socket'
require 'log_switch'
require_relative 'host/attributes'
Dir[File.dirname(__FILE__) + '/host/shells/*.rb'].each(&method(:require))
require_relative 'file_system'
require_relative 'service_manager'
require_relative 'package_manager'
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

    def users
      @users ||= Rosh::UserManager.new(@name)
    end

    # Access to the PackageManager for the Host's OS type.
    #
    # @return [Rosh::PackageManager]
    # @see Rosh::PackageManager
    def packages
      @package ||= Rosh::PackageManager.new(@name)
    end

    # Access to the ServiceManager for the Host's OS type.
    #
    # @return [Rosh::ServiceManager]
    # @see Rosh::ServiceManager
    def services
      @service_manager ||= Rosh::ServiceManager.new(@name)

=begin
      @service_manager = case operating_system
      when :darwin
        Rosh::Host::ServiceManager.new(@name, :launch_ctl)
      when :linux
        Rosh::Host::ServiceManager.new(@name, :init)
      when :freebsd
        Rosh::Host::ServiceManager.new(@name, :init)
      end
=end
    end

    def local?
      @name == 'localhost'
    end
  end
end
