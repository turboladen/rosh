class Rosh
  module Changeable
    def change_if(criteria, &block)
      if execute_action?(criteria)
        return block.call
      end

      puts 'Check state first and criteria met.  Returning.'
    end

    private

    def execute_action?(criteria)
      return true unless current_shell.check_state_first?

      puts 'Checking state before changes...'

      if criteria.is_a? Array
        return criteria.any?(&:call) ? true : false
      end

      return true if criteria.kind_of?(Proc) && criteria.call
      return true if !criteria.kind_of?(Proc) && criteria

      false
    end
  end
end
