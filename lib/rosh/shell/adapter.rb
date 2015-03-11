require_relative '../logger'

class Rosh
  class Shell
    class Adapter
      include Rosh::Logger

      attr_accessor :su_user_name
      attr_reader :workspace

      def initialize(type, host_name)
        @host_name = host_name
        load_adapter(type)
      end

      def sudo
        @sudo ||= false
      end

      def sudo=(new_value)
        @sudo = new_value
      end

      private

      def load_adapter(type)
        case type
        when :local
          require_relative 'adapters/local'
          self.extend Rosh::Shell::Adapters::Local
        else
          require_relative 'adapters/remote'
          self.extend Rosh::Shell::Adapters::Remote
        end
      end
    end
  end
end
