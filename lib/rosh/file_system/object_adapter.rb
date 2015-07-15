require_relative '../logger'

class Rosh
  class FileSystem
    class ObjectAdapter
      include Rosh::Logger

      def initialize(path, type, host_name)
        @path = path
        @host_name = host_name

        @adapter_class = load_adapter(type)
      end

      # @return [Rosh::Host]
      def host
        Rosh.find_by_host_name(@host_name)
      end

      def path=(new_path)
        @path = new_path
        private_result(@path, 0)
      end

      def to_path
        private_result(@path, 0)
      end

      def class
        @adapter_class
      end

      private

      def load_adapter(type)
        require_relative "object_adapters/#{type}"
        klass =
          Rosh::FileSystem::ObjectAdapters.const_get(type.to_s.classify)
        self.extend klass

        klass
      end
    end
  end
end
