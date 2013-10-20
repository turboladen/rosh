require 'observer'

class Rosh
  module Observable
    include ::Observable

    # Only notifies if the result of the block is truthy and criteria evaluates
    # to true (if given).  Returns the result of the block.
    #
    # @param [Object] watched_object
    # @param [Symbol] attribute
    # @param [Object] from
    # @param [Object] to
    # @param [Object] criteria
    # @return [Object]
    def notify_about(watched_object, attribute, from: from, to: to, criteria: nil, &block)
      result = block.call
      criteria_met = criteria.nil? || criteria.kind_of?(Proc) ? criteria.call : criteria

      if criteria_met && result
        watched_object.changed
        watched_object.notify_observers(watched_object,
          attribute,
          from,
          to,
          current_shell.su?
        )
      end

      result
    end
  end
end
