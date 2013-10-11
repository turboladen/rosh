class Rosh
  module Changeable
    def change(watched_object, attribute, from: from, to: to, criteria: criteria, &block)
      if skip_action?(criteria)
        puts 'Check state first and criteria met.  Returning.'
        return
      end

      result = block.call

      watched_object.changed
      watched_object.notify_observers(watched_object,
        attribute: attribute,
        old_value: from,
        new_value: to,
        as_sudo: current_shell.su?
      )

      result
    end

    private

    def skip_action?(criteria)
      if current_shell.check_state_first?
        puts 'Checking state before changes...'

        if criteria.is_a?(Array)
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
      end

      false
    end
  end
end
