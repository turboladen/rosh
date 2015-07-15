class Rosh
  class ServiceManager
    class ObjectAdapter
      attr_accessor :service_name

      def initialize(name, type, host_name)
        @service_name = name
        @host_name = host_name

        load_adapter(type)
      end

      def build_info(status, pid: nil, process_info: nil)
        process_info = if pid
          current_shell.ps(pid: pid)
        elsif process_info
          process_info
        else
          current_shell.ps(name: @service_name)
        end

        if pid #&& !process_info.empty?
          status = :running
        end

        {
          name: @service_name,
          status: status,
          processes: process_info
        }
      end

      def update_attribute(key, value)
        self.send("#{key}=", value)
      end

      private

      def load_adapter(type)
        require_relative "object_adapters/#{type}"
        klass =
          Rosh::ServiceManager::ObjectAdapters.const_get(type.to_s.classify)
        self.extend klass
      end
    end
  end
end
