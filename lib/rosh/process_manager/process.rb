require_relative '../changeable'
require_relative '../observable'


class Rosh
  class ProcessManager
    class ProcessNotFound < RuntimeError; end

    class Process
      include Rosh::Changeable
      include Rosh::Observable


      attr_reader :pid
      attr_accessor :struct

      def initialize(process_id, host_name)
        @host_name = host_name
        @pid = process_id
      end


      def send_signal(sig)
        adapter.send_signal(sig)
      end

      private

      def adapter
        return @adapter if @adapter

        @adapter = if current_host.local?
          require_relative 'object_adapters/local'
          ProcessManager::ObjectAdapters::Local
        else
          require_relative 'object_adapters/remote'
          ProcessManager::ObjectAdapters::Remote
        end

        @adapter.pid = @pid
        @adapter.host_name = @host_name

        @adapter
      end
    end
  end
end
