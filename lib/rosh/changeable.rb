class Rosh
  module Changeable
    def change_if(criteria, &block)
      if skip_action?(criteria)
        puts 'Check state first and criteria met.  Returning.'
        return
      end

      block.call
    end

    private

    def skip_action?(criteria)
      return unless current_shell.check_state_first?

      puts 'Checking state before changes...'

      if criteria.is_a? Array
        criteria.each do |c|
          return true if c.call
        end

        return false
      end

      if criteria.kind_of?(Proc) && criteria.call
        return true
      elsif !criteria.kind_of?(Proc) && criteria
        return true
      end

      false
    end
  end
end
