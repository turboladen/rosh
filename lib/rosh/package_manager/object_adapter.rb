class Rosh
  class PackageManager
    class ObjectAdapter
      def initialize(package_name, type, host_name)
        @package_name = package_name
        @host_name = host_name

        load_adapter(type)
      end

      def bin_path=(new_bin_path)
        @bin_path = new_bin_path
      end

      def update_attribute(key, value)
        self.send("#{key}=", value)
      end

      private

      def load_adapter(type)
        require_relative "object_adapters/#{type}"
        klass =
          Rosh::PackageManager::ObjectAdapters.const_get(type.to_s.capitalize.to_sym)
        self.extend klass
        @bin_path = klass::DEFAULT_BIN_PATH
      end
    end
  end
end
