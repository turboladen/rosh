require_relative '../string_refinements'


class Rosh
  class FileSystem
    class ManagerAdapter
      def initialize(type, host_name)
        @host_name = host_name

        load_adapter(type)
      end

      private

      def load_adapter(type)
        require_relative "manager_adapters/#{type}"
        klass =
          Rosh::FileSystem::ManagerAdapters.const_get(type.to_s.classify)
        self.extend klass
      end
    end
  end
end
