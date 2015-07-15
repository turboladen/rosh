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

      attr_writer :sudo

      private

      def load_adapter(type)
        case type
        when :local
          require_relative 'adapters/local'
          extend Rosh::Shell::Adapters::Local
        else
          require_relative 'adapters/remote'
          extend Rosh::Shell::Adapters::Remote
        end
      end
    end
  end
end
