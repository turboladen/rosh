require 'shellwords'
require 'highline/import'
require 'log_switch'
require_relative 'kernel_refinements'
require_relative 'shell/adapter'
require_relative 'shell/commands'


class Rosh
  class Shell
    extend LogSwitch
    include LogSwitch::Mixin
    include Rosh::Shell::Commands

    # @!attribute sudo
    #   @return [Boolean] Set to enable/disable sudo mode.  Once enabled, all subsequent
    #     commands will be run as sudo or until it is disabled.
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
    def exit(status=0)
      echo_rosh_command status

      Kernel.exit(status)
    end

    # @return [Exception] the last exception that was raised.
    def last_exception
      return nil if @history.empty?
      exception = @history.reverse.find { |result| result[:output].kind_of? Exception }

      exception[:output]
    end
    alias :_! :last_exception

    # @return [Integer] the exit status code of the last command executed.
    def last_exit_status
      @history.empty? ? nil : @history.last[:exit_status]
    end
    alias :_? :last_exit_status

    # @return [String] the output of the last command.
    def last_result
      @history.empty? ? nil : @history.last[:output]
    end
    alias :__ :last_result

    # Run commands in the +block+ as sudo.
    #
    # @return Returns whatever the +block+ returns.
    # @yields [Rosh::Host::Shells::*] the current Rosh shell.
    def su(user=nil, &block)
      @sudo = true
      adapter.sudo = true
      log 'sudo enabled'
      current_pwd = @internal_pwd

      su_user = if user
        u = current_host.users[user]
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
      self.public_methods(false) | Commands.instance_methods
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

      if current_host.local?
        @adapter = Shell::Adapter.new(:local, @host_name)
      else
        @adapter = Shell::Adapter.new(:remote, @host_name)
        @adapter.ssh_options = @ssh_options
        @adapter.user = @user
      end

      @internal_pwd = if current_host.local?
        Dir.pwd
      else
        @adapter.exec('pwd')[2].strip
      end

      @adapter
    end

    def process(cmd, *args, **options)
      cmd_result = yield

      @history << cmd_result
      current_host.update_history(cmd, cmd_result.ruby_object,
        cmd_result.exit_status, args, options)

      if cmd_result.exit_status.zero?
        current_host.update_stdout(cmd_result.string)
      else
        current_host.update_stderr(cmd_result.string)
      end

      cmd_result.ruby_object
    end
  end
end
