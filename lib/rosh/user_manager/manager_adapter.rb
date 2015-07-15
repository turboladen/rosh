class Rosh
  class UserManager
    class ManagerAdapter
      def initialize(type, host_name)
        @host_name = host_name

        load_adapter(type)
      end

      def open_directory?
        current_host.darwin?
      end

      private

      def load_adapter(type)
        require_relative "manager_adapters/#{type}"
        klass =
          Rosh::UserManager::ManagerAdapters.const_get(type.to_s.classify)
        self.extend klass
      end
    end
  end
end
