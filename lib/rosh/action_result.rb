require 'json'
require 'yaml'
require 'net/ssh/simple'


class Rosh

  # Used for serializing the results of Actions.  If the +ssh_output+ that's
  # passed in at #initialize is a Net::SSH::Simple::Error, that error is stored
  # and accessible through #exception so that consumers can deal with the error
  # later.
  class ActionResult

    # @return [Symbol] Used by Rosh to determine if the command
    #   succeeded or not.  Options are +:updated+, +:no_change+, or +:failed+.
    attr_accessor :status

    # @return [String] STDOUT from the remote host after executing the command.
    attr_reader :stdout

    # @return [String] STDERR from the remote host after executing the command.
    attr_reader :stderr

    # @return [String] The command that was executed on the remote host.
    attr_reader :command

    # @return [Number] Exit code from running the command on the remote host.
    attr_reader :exit_code

    # @return [Time] Time the SSH operation started.
    attr_reader :started_at

    # @return [Time] Time the SSH operation finished.
    attr_reader :finished_at

    # @return [Time] Time of the last SSH activity.
    attr_reader :last_event_at

    # @return [Time] Time of the last SSH keepalive.
    attr_reader :last_keepalive_at

    # @return [Hash] Options used in making the SSH connection.
    attr_reader :ssh_options

    # @return [Exception] If an Exception occurred, it is captured here to allow
    #   for ActionResult consumers to deal with.
    attr_reader :exception


    # @param [Net::SSH::Simple::Result,Net::SSH::Simple::Error] ssh_output The
    #   result of running a Net::SSH::Simple command.
    # @param [Symbol] status Used by Rosh to determine if the command
    #   succeeded or not.  Options are +:updated+, +:no_change+, or +:failed+.
    def initialize(ssh_output, status=nil)
      if ssh_output.is_a? ::Net::SSH::Simple::Error
        @exception = ssh_output.wrapped
        ssh_output = ssh_output.result
        status = :failure
      end

      @status = status
      @stdout = ssh_output.stdout
      @stderr = ssh_output.stderr
      @command = ssh_output.cmd
      @started_at = ssh_output.start_at
      @finished_at = ssh_output.finish_at
      @last_event_at = ssh_output.last_event_at
      @last_keepalive_at = ssh_output.last_keepalive_at
      @ssh_options = ssh_output.opts
      @exit_code = ssh_output.exit_code
    end

    # @return [Boolean] Tells if the result was an exception.  Exceptions are
    #   not representative of failed commands--they are, rather, most likely
    #   due to a problem with making the SSH connection.
    def exception?
      !!@exception
    end

    def failed?
      @status == :failed
    end

    def no_change?
      @status == :no_change
    end

    def updated?
      @status == :updated
    end

    # @return [Hash] All attributes as a Hash.
    def to_hash
      instance_variables.inject({}) do |result, ivar|
        key = ivar.to_s.delete('@').to_sym
        result[key] = instance_variable_get(ivar)
        result
      end
    end

    # @return [String] All attributes as JSON.
    def to_json
      self.to_hash.to_json
    end

    # @return [String] All attributes as YAML.
    def to_yaml
      self.to_hash.to_yaml
    end
  end
end
