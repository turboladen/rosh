require 'etc'
require 'socket'
require 'drama_queen/producer'
require 'drama_queen/consumer'

require_relative 'logger'
require_relative 'host/attributes'
require_relative 'file_system'
require_relative 'service_manager'
require_relative 'package_manager'
require_relative 'process_manager'
require_relative 'user_manager'

class Rosh
  # Object that represents a computer that Rosh commands are sent to.
  class Host
    include Rosh::Logger
    include Host::Attributes
    include DramaQueen::Consumer
    include DramaQueen::Producer

    DISTRIBUTION_METHODS = %i[distribution distribution_version]

    DISTRIBUTION_METHODS.each do |meth|
      define_method(meth) do
        distro, version = case operating_system
                          when :linux
                            extract_linux_distribution
                          when :darwin
                            extract_darwin_distribution
                          end

        @distribution = distro
        @distribution_version = version.strip

        instance_variable_get("@#{meth}".to_sym)
      end
    end

    # @param [String] host_name
    # @return [Boolean]
    def self.local?(host_name)
      %W[localhost #{Socket.gethostname}].include? host_name
    end

    # @!attribute [r] name
    #   The host name (aka hostname)
    #   @return [String]
    attr_reader :name

    # @!attribute [r] shell
    #   The Rosh::Shell object that's used by this object for running
    #   (some/many/most) commands.
    #   @return [Rosh::Shell]
    attr_reader :shell

    # @!attribute [r] user
    #   The name of the user using the host.
    #   @todo Should this really be on the Host?? or on the Shell? Seems like
    #     the latter.
    #   @todo If it stays here, should probably be a Rosh::User.
    #   @return [String]
    attr_reader :user

    # @!attribute [r] history
    #   A list of commands executed on this Host.
    #   @return [Array<Rosh::Command>]
    attr_reader :history

    # Set to +true+ to tell the command to check the
    # state of the object its working on before working on it.  For
    # example, when enabled and running a command to create a user "joe"
    # will check to see if "joe" exists before creating it.  Defaults to
    # +false+.
    # @!attribute [w] idempotent_mode
    attr_writer :idempotent_mode

    # @param [String] host_name
    # @param [Hash] ssh_options
    def initialize(host_name, **ssh_options)
      @name = host_name
      @user = ssh_options[:user] || Etc.getlogin
      @shell = Rosh::Shell.new(@name, ssh_options)

      @idempotent_mode = false
      @history = []
      @kernel_version = nil
      @architecture = nil

      @distribution = nil
      @distribution_version = nil

      @remote_shell_type = nil
      log "Subscribing to #{commands_queue}..."
      subscribe commands_queue, :process_result
    end

    def commands_queue
      "rosh.commands.#{@name}"
    end

    # @return [Boolean] Returns if commands are set to check the state of
    #   host objects to determine if the command needs to be run.
    def idempotent_mode?
      @idempotent_mode
    end

    # Receives Rosh::Shell::PrivateCommandResults on the 'rosh.command_results'
    # message queue.  Allows for many classes to publish to and this to get
    # notifications.
    #
    # @param [Rosh::Command] command
    def process_result(command)
      prefix = "#{self.class}:#{name}"
      puts "command class: #{command.class}"
      # log "#{prefix} received command on queue: #{command}"
      # log "#{prefix} Command name: #{command.method.name}"
      # log "#{prefix} Command args: #{command.method_arguments}"
      # log "#{prefix} Command result: #{command.result.ruby_object}"
      history << command
    end

    def update
      puts 'update called'
    end

    def last_exception
      return nil if @history.empty?
      exception = @history.reverse.find do |event|
        event[:result].is_a? Exception
      end

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
    def su(user = nil, &block)
      @shell.su(user, &block)
    end

    # @return [Boolean]
    def local?
      self.class.local?(@name)
    end

    # @return [Symbol]
    def operating_system
      return @operating_system if @operating_system

      command = 'uname -a'
      result = @shell.exec(command)
      extract_os(result)

      @operating_system
    end

    # @return [String]
    def kernel_version
      command = 'uname -a'
      result = @shell.exec(command)
      extract_os(result)

      @kernel_version
    end

    # @return [Symbol]
    def architecture
      return @architecture if @architecture

      command = 'uname -a'
      result = @shell.exec(command)
      extract_os(result)

      @architecture
    end

    # The name of the remote shell for the user on host_name that initiated the
    # Rosh::SSH connection for the host.
    #
    # @return [String] The shell type.
    def remote_shell_type
      command = 'echo $SHELL'
      result = @shell.exec(command)
      stdout = result.stdout
      log "STDOUT: #{stdout}"
      /(?<shell>[a-z]+)$/ =~ stdout

      shell.to_sym
    end

    def darwin?
      operating_system == :darwin
    end

    def linux?
      operating_system == :linux
    end

    #---------------------------------------------------------------------------
    # Privates
    #---------------------------------------------------------------------------

    private

    # Extracts info about the operating system based on uname info.
    #
    # @param [Rosh::CommandResult] result The result of the `uname -a`
    #   command.
    def extract_os(result)
      log "STDOUT: #{result}"

      /^(?<os>[a-zA-Z]+) (?<uname>[^\n]*)/ =~ result.strip
      @operating_system = os.to_safe_down_sym

      case @operating_system
      when :darwin
        /Kernel Version (?<version>\d\d\.\d\d?\.\d\d?).*RELEASE_(?<arch>\S+)/ =~ uname
      when :linux
        /\S+\s+(?<version>\S+).*\s(?<arch>(x86_64|i386|i586|i686)).*$/ =~ uname
      when :freebsd
        /\S+\s+(?<version>\S+).*\s(?<arch>\S+)\s*$/ =~ uname
      end

      @kernel_version = version
      @architecture = arch.downcase.to_sym
    end

    # Extracts info about the distribution.
    def extract_linux_distribution
      distro, version = catch(:distro_info) do
        stdout = @shell.exec('lsb_release --description')
        /Description:\s+(?<distro>\w+)\s+(?<version>[^\n]+)/ =~ stdout
        throw(:distro_info, [distro, version]) if distro && version

        stdout = @shell.exec('cat /etc/redhat-release')
        /(?<distro>\w+)\s+release\s+(?<version>[^\n]+)/ =~ stdout
        throw(:distro_info, [distro, version]) if distro && version

        stdout = @shell.exec('cat /etc/slackware-release')
        /(?<distro>\w+)\s+release\s+(?<version>[^\n]+)/ =~ stdout
        throw(:distro_info, [distro, version]) if distro && version

        stdout = @shell.exec('cat /etc/gentoo-release')
        /(?<distro>\S+).+release\s+(?<version>[^\n]+)/ =~ stdout
        throw(:distro_info, [distro, version]) if distro && version
      end

      [distro.to_safe_down_sym, version]
    end

    def extract_darwin_distribution
      stdout = @shell.exec 'sw_vers'
      /ProductName:\s+(?<distro>[^\n]+)\s*ProductVersion:\s+(?<version>\S+)/m =~ stdout

      [distro.to_safe_down_sym, version]
    end
  end
end

require_relative '../ext/kernel_refinements'
require_relative 'shell'
