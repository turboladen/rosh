class Rosh
  class ProcessManager
    class ObjectAdapter
      def initialize(pid, type, host_name)
        @pid = pid
        @host_name = host_name

        load_adapter(type)
      end

      def pid=(new_pid)
        @pid = new_pid
      end

      private

      def load_adapter(type)
        require_relative "object_adapters/#{type}"
        klass =
          Rosh::ProcessManager::ObjectAdapters.const_get(type.to_s.classify)
        self.extend klass
      end
    end
  end
end
