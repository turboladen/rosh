require_relative '../logger'
require_relative '../host_methods'

class Rosh
  class FileSystem
    class ObjectAdapter
      include Rosh::Logger
      include Rosh::HostMethods

      def initialize(path, type, host_name)
        @path = path
        @host_name = host_name

        @adapter_class = load_adapter(type)
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
        extend klass

        klass
      end
    end
  end
end
