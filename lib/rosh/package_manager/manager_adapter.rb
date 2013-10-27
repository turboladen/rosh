require_relative '../string_refinements'


class Rosh
  class PackageManager
    class ManagerAdapter
      def initialize(type, host_name)
        @host_name = host_name

        load_adapter(type)
      end

      def bin_path=(new_bin_path)
        @bin_path = new_bin_path
      end

      private

      def load_adapter(type)
        require_relative "manager_adapters/#{type}"
        klass =
          Rosh::PackageManager::ManagerAdapters.const_get(type.to_s.classify)
        self.extend klass
        @bin_path = klass::DEFAULT_BIN_PATH
      end
    end
  end
end
