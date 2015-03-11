require 'etc'
require 'socket'
require 'drama_queen/producer'
require 'drama_queen/consumer'

require_relative 'logger'
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
    include Rosh::Logger
    include Host::Attributes
    include DramaQueen::Consumer
    include DramaQueen::Producer

    attr_reader :name
    attr_reader :shell
    attr_reader :user
    attr_reader :history

    # Set to +true+ to tell the command to check the
    # state of the object its working on before working on it.  For
    # example, when enabled and running a command to create a user "joe"
    # will check to see if "joe" exists before creating it.  Defaults to
    # +false+.
    # @!attribute [w] idempotent_mode
    attr_writer :idempotent_mode

    def initialize(host_name, **ssh_options)
      @name = host_name
      @user = ssh_options[:user] || Etc.getlogin
      @shell = Rosh::Shell.new(@name, ssh_options)
      @idempotent_mode = false
      @history = []
      subscribe 'rosh.commands', :process_result
    end

    # @return [Boolean] Returns if commands are set to check the state of
    #   host objects to determine if the command needs to be run.
    def idempotent_mode?
      !!@idempotent_mode
    end

    # Receives Rosh::Shell::PrivateCommandResults on the 'rosh.command_results'
    # message queue.  Allows for many classes to publish to and this to get
    # notifications.
    #
    # @param [Rosh::Command] command
    def process_result(command)
      log "#{self.class}:#{name} received command on queue: #{command}"
      log "#{self.class}:#{name} Command name: #{command.method.name}"
      log "#{self.class}:#{name} Command args: #{command.method_arguments}"
      log "#{self.class}:#{name} Command result: #{command.result.ruby_object}"
      @history << command
    end

    def update
      puts 'update called'
    end

    def last_exception
      return nil if @history.empty?
      exception = @history.reverse.find { |event| event[:result].kind_of? Exception }

      exception[:output]
    end

    def last_exit_status
      @history.empty? ? nil : @history.last[:exit_status]
    end

    def last_result
      @history.empty? ? nil : @history.last[:result]
    end

    def update_stdout(string)
      publish('stdout', string)
    end

    def update_stderr(string)
      publish('stderr', string)
    end

    def update_history(cmd, ruby_object, exit_status, *args, **options)
      @history << {
        time: Time.now.to_s,
        command: cmd,
        result: ruby_object,
        exit_status: exit_status,
        arguments: args.compact,
        options: options
      }

      puts "History updated: #{@history.last}"
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
      subscribe 'rosh.file_system', :update

      @file_system
    end

    # Access to the UserManager for the Host's OS type.
    #
    # @return [Rosh::UserManager]
    # @see Rosh::UserManager
    def users
      return @user_manager if @user_manager

      @user_manager = Rosh::UserManager.new(@name)
      subscribe 'rosh.user_manager', :update

      @user_manager
    end

    # Access to the PackageManager for the Host's OS type.
    #
    # @return [Rosh::PackageManager]
    # @see Rosh::PackageManager
    def packages
      return @package_manager if @package_manager

      @package_manager = Rosh::PackageManager.new(@name)
      subscribe 'rosh.package_manager', :update

      @package_manager
    end

    # Access to the ProcessManager for the Host's OS type.
    #
    # @return [Rosh::ProcessManager]
    # @see Rosh::ProcessManager
    def processes
      return @process_manager if @process_manager

      @process_manager = Rosh::ProcessManager.new(@name)
      subscribe 'rosh.process_manager', :update

      @process_manager
    end

    # Access to the ServiceManager for the Host's OS type.
    #
    # @return [Rosh::ServiceManager]
    # @see Rosh::ServiceManager
    def services
      return @service_manager if @service_manager

      @service_manager = Rosh::ServiceManager.new(@name)
      subscribe 'rosh.service_manager', :update

      @service_manager
    end

    # @param [String] user
    # @param [Proc] block The code to execute in the sudo context.
    def su(user=nil, &block)
      @shell.su(user, &block)
    end

    # @return [Boolean]
    def local?
      %W[localhost #{Socket.gethostname}].include? @name
    end
  end
end
