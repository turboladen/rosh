require 'shellwords'
require 'highline/import'
require_relative 'logger'
require_relative 'shell/adapter'
require_relative 'shell/commands'
require_relative 'host_methods'

class Rosh
  # Object that each Rosh::Host uses to execute commands.
  class Shell
    include Rosh::Logger
    include Rosh::Shell::Commands
    include Rosh::HostMethods

    # @!attribute sudo
    #   @return [Boolean] Set to enable/disable sudo mode.  Once enabled, all
    #     subsequent commands will be run as sudo or until it is disabled.
    attr_accessor :sudo

    # @return [Array<Hash>] the list of commands that the shell has executed
    #   throughout its life.
    attr_reader :history

    def initialize(host_name, **ssh_options)
      @host_name = host_name
      @ssh_options = ssh_options
      @history = []
      @sudo = false
      @internal_pwd = nil
      @workspace = nil
    end

    # @param [Integer] status Exit status code.
    def exit(status = 0)
      echo_rosh_command status

      Kernel.exit(status)
    end

    # @return [Exception] the last exception that was raised.
    def last_exception
      return if @history.empty?

      exception = @history.reverse.find do |result|
        result[:output].is_a? Exception
      end

      exception[:output]
    end
    alias_method :_!, :last_exception

    # @return [Integer] the exit status code of the last command executed.
    def last_exit_status
      @history.empty? ? nil : @history.last.exit_status
    end
    alias_method :_?, :last_exit_status

    # @return [String] the output of the last command.
    def last_result
      @history.empty? ? nil : @history.last[:output]
    end
    alias_method :__, :last_result

    # Run commands in the +block+ as sudo.
    #
    # @return Returns whatever the +block+ returns.
    # @yield [Rosh::Host::Shells::*] the current Rosh shell.
    def su(user = nil, &block)
      @sudo = true
      adapter.sudo = true
      log 'sudo enabled'
      current_pwd = @internal_pwd

      su_user = if user
                  u = host.users[user]
                  adapter.su_user_name = u.name
                  @internal_pwd = adapter.exec('pwd')[2].strip
                  u
                end

      result = block.call(su_user)

      @internal_pwd = current_pwd
      adapter.su_user_name = nil
      adapter.sudo = false
      @sudo = false
      log 'sudo disabled'

      result
    end

    def shell_methods
      public_methods(false) | Commands.instance_methods
    end

    # Are commands being run as sudo?
    #
    # @return [Boolean]
    def su?
      @sudo
    end

    # @return [Array<String>] List of commands given in the PATH.
    def system_commands
      env_internal[:path].map do |dir|
        Dir["#{dir}/*"].map { |f| ::File.basename(f) }
      end.flatten
    end

    def upload(source_path, destination_path)
      adapter.upload(source_path, destination_path)
    end

    # Called by serializer when dumping.
    def encode_with(coder)
      coder['host_name'] = @host_name
      coder['user'] = @user
      o = @ssh_options.dup
      o.delete(:password) if o[:password]
      o.delete(:user) if o[:user]

      coder['ssh_options'] = o
    end

    # Called by serializer when loading.
    def init_with(coder)
      @user = coder['user']
      @ssh_options = coder['ssh_options']
      @host_name = coder['host_name']
      @sudo = false
      @history = []
    end

    def workspace
      adapter.workspace
    end

    private

    def adapter
      return @adapter if @adapter

      if host.local?
        @adapter = Shell::Adapter.new(:local, @host_name)
      else
        @adapter = Shell::Adapter.new(:remote, @host_name)
        @adapter.ssh_options = @ssh_options
        @adapter.user = @user
      end

      @internal_pwd = if host.local?
                        Dir.pwd
                      else
                        @adapter.exec('pwd').string.strip
                      end

      @adapter
    end

    def process(cmd, *args, **options)
      cmd_result = yield

      @history << cmd_result
      # TODO: Host#update_history now takes 1 param: Command.
      host.update_history(cmd, cmd_result.ruby_object,
        cmd_result.exit_status, args, options)

      if cmd_result.exit_status.zero?
        host.update_stdout(cmd_result.string)
      else
        host.update_stderr(cmd_result.string)
      end

      cmd_result.ruby_object
    end
  end
end
