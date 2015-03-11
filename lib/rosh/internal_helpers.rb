require_relative 'command'

class Rosh
  module InternalHelpers
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # Shortcut for creating a new non-idempotent command and running it.
      def _run_command(method, *args, &method_code)
        Rosh::Command.new(method, *args, &method_code).execute!
      end
    end
  end
end
