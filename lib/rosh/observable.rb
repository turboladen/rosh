require 'observer'

class Rosh
  module Observable
    include ::Observable

    def notify_about(watched_object, attribute, from: from, to: to, criteria: nil, &block)
      result = block.call

      if criteria.nil? || criteria.call
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
