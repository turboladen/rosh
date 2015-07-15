class Rosh
  class ProcessManager
    class ManagerAdapter
      def initialize(type, host_name)
        @host_name = host_name

        load_adapter(type)
      end

      private

      def load_adapter(type)
        class_name = "#{type}_process_manager"
        require_relative "manager_adapters/#{class_name}"
        klass =
          Rosh::ProcessManager::ManagerAdapters.const_get(class_name.classify)
        self.extend klass
      end
    end
  end
end
