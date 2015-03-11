require 'drama_queen/producer'
require_relative 'logger'


class Rosh
  # A Command object captures the name of command, arguments for the command,
  # and the result of the command after it has been executed. After executing,
  # the instance of the Command is published over the 'rosh.commands' exchange.
  class Command
    include DramaQueen::Producer
    include Rosh::Logger

    attr_reader :name

    attr_reader :method
    attr_reader :method_arguments

    attr_reader :result
    attr_reader :executed_at

    attr_writer :change_if
    attr_writer :did_change_succeed
    attr_writer :after_change

    # @param [Method] command_method
    # def initialize(name, method, *method_arguments)
    def initialize(method, *method_arguments, &method_action)
      # @name = name
      @method = method
      @method_arguments = *method_arguments
      @method_action = method_action
      @result = nil
      @executed_at = nil

      @change_if = nil
      @did_change_succeed = nil
      @after_change = nil
    end

    # @param [Boolean] no_change_needed Only applies to if the Host is in
    #   idempotent mode.  If it is and this expression evaluates to +true+
    #   then the running of the command is skipped, a PrivateCommandResult is
    #   published describing this, and the Symbol +:idempotent_skip+ is returned.
    #   If idempotent mode is enabled on the host and this evaluates to +false+,
    #   then the +cmd_block+ is executed.  If  idempotency mode is disabled,
    #   this parameter is disregarded and the +cmd_block+ is executed.
    # @return [Object]
    def execute!
      if Rosh.environment.current_host.idempotent_mode? && @change_if
        log "Idempotency: #{Rosh.environment.current_host.name} is in idempotent mode"
        run_idempotent
      else
        if Rosh.environment.current_host.idempotent_mode?
          log "Command is static (non-idempotent)"
        else
          log "Idempotency: #{Rosh.environment.current_host.name} NOT in idempotent mode"
        end

        run_static
      end
    end

    private

    def run_idempotent
      should_change = @change_if.call
      log "Object should change: #{should_change}"

      if should_change
        @executed_at = Time.now
        @result = call_method
        publish 'rosh.commands', self

        if @did_change_succeed.call
          log 'Object did change! Calling @after_change...'
          @after_change.call(@result)
        else
          fail 'Tried to change object, but change failed'
        end

        @result.ruby_object
      else
        @result = private_result(false, -1, 'Idempotency mode enabled and nothing to do.')
        @result.ruby_object
      end
    end

    # @param [Array<Proc>, Proc] cmd_block Used for when the Host's
    #   +idempotent_mode+ is set to true.  If any of the Proc objects given
    #   evaluate to true, the command will be executed.  If the Host's
    #   +idempotent_mode+ is set to false, this won't be checked; the command
    #   will always be executed.
    def run_static
      @executed_at = Time.now
      @result = call_method
      publish 'rosh.commands', self

      @result.ruby_object
    end


    def call_method
      log "Calling method: #{@method.name}"
      @method_arguments.empty? ? @method_action.call : @method_action.call(*@method_arguments)
    end
  end
end
