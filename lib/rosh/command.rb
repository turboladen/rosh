require 'drama_queen/producer'
require_relative 'logger'


class Rosh
  module Command
    include DramaQueen::Producer
    include LogSwitch
    extend LogSwitch::Mixin

    def self.included(base)
      base.send(:include, LogSwitch)
      base.extend(LogSwitch::Mixin)
    end

    # @param [Array<Proc>, Proc] cmd_block Used for when the Host's
    #   +idempotent_mode+ is set to true.  If any of the Proc objects given
    #   evaluate to true, the command will be executed.  If the Host's
    #   +idempotent_mode+ is set to false, this won't be checked; the command
    #   will always be executed.
    def run_command(&cmd_block)
      cmd_result = cmd_block.call
      publish 'rosh.command_results', cmd_result

      cmd_result.ruby_object
    end

    # @param [Boolean] no_change_needed Only applies to if the Host is in
    #   idempotent mode.  If it is and this expression evaluates to +true+
    #   then the running of the command is skipped, a PrivateCommandResult is
    #   published describing this, and the Symbol +:idempotent_skip+ is returned.
    #   If idempotent mode is enabled on the host and this evaluates to +false+,
    #   then the +cmd_block+ is executed.  If  idempotency mode is disabled,
    #   this parameter is disregarded and the +cmd_block+ is executed.
    # @return [Object]
    def run_idempotent_command(no_change_needed, &cmd_block)
      log "Idempotency: No change needed evaluates to: #{no_change_needed}"

      cmd_result = if current_host.idempotent_mode?
        log "Idempotency: #{current_host.name} is in idempotent mode"

        if no_change_needed
          private_result(:idempotent_skip, -1, 'Idempotency mode enabled and nothing to do.')
        else
          cmd_block.call
        end
      else
        cmd_block.call
      end

      publish 'rosh.command_results', cmd_result

      cmd_result.ruby_object
    end

    private

    def all_true? idempotency_check
      if idempotency_check.is_a? Array
        return idempotency_check.all? do |blk|
          blk.call
        end
      end

      if idempotency_check.kind_of?(Proc)
        return idempotency_check.call
      end

      return true if idempotency_check

      false
    end

    def any_true? idempotency_check
      if idempotency_check.is_a? Array
        return idempotency_check.any? do |blk|
          blk.call
        end
      end

      if idempotency_check.kind_of?(Proc)
        return idempotency_check.call
      end

      return true if idempotency_check

      false
    end
  end
end
