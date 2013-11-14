require 'log_switch'
require 'drama_queen/producer'


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

    def run_idempotent_command(no_change_needed, &cmd_block)
      cmd_result = if current_host.idempotent_mode?
        log "Idempotency: #{current_host.name} is in idempotent mode"

        if no_change_needed
          log 'Idempotency: no change needed.'
          private_result(:idempotent_skip, 0)
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
