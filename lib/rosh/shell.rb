require 'shellwords'
require 'highline/import'
require 'log_switch'
require_relative 'kernel_refinements'
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

    # Set to +true+ to tell the shell to check the
    # state of the object its working on before working on it.  For
    # example, when enabled and running a command to create a user "joe"
    # will check to see if "joe" exists before creating it.  Defaults to
    # +false+.
    # @!attribute [w] check_state_first
    attr_writer :check_state_first

    # @return [Array<Hash>] the list of commands that the shell has executed
    #   throughout its life.
    attr_reader :history


    def initialize(host_name, **ssh_options)
      @host_name = host_name
      @ssh_options = ssh_options
      @history = []
      @sudo = false
      @check_state_first = false
      @internal_pwd = nil
    end

    # @return [Boolean] Returns if the shell is set to check the state of
    #   commands to determine if the command needs to be run.
    def check_state_first?
      !!@check_state_first
    end

    # @param [Integer] status Exit status code.
    def exit(status=0)
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
    def su(&block)
      @sudo = true
      adapter.sudo = true
      log 'sudo enabled'

      result = block.call(self)

      adapter.sudo = false
      @sudo = false
      log 'sudo disabled'

      result
    end

    # Are commands being run as sudo?
    #
    # @return [Boolean]
    def su?
      @sudo
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

    private

    def adapter
      return @adapter if @adapter

      if current_host.local?
        require_relative 'shell/adapters/local'
        @adapter = Shell::Adapters::Local
      else
        require_relative 'shell/adapters/remote'
        @adapter = Shell::Adapters::Remote
        @adapter.ssh_options = @ssh_options
      end

      @adapter.host_name = @host_name

      @internal_pwd = if current_host.local?
        Dir.pwd
      else
        @adapter.exec 'pwd'
      end

      @adapter
    end
  end
end
