require_relative '../string_refinements'


class Rosh
  class FileSystem
    class ObjectAdapter
      def initialize(path, type, host_name)
        @path = path
        @host_name = host_name

        load_adapter(type)
      end

      def path=(new_path)
        @path
      end

      def to_path
        @path
      end

      private

      def load_adapter(type)
        require_relative "object_adapters/#{type}"
        klass =
          Rosh::FileSystem::ObjectAdapters.const_get(type.to_s.classify)
        self.extend klass
      end
    end
  end
end
