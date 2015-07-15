class Rosh
  class ServiceManager
    class ManagerAdapter
      def initialize(type, host_name)
        @host_name = host_name

        load_adapter(type)
      end

      private

      def load_adapter(type)
        require_relative "manager_adapters/#{type}"
        klass =
          Rosh::ServiceManager::ManagerAdapters.const_get(type.to_s.classify)
        self.extend klass
      end
    end
  end
end
