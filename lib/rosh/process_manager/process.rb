require_relative 'object_adapter'

class Rosh
  class ProcessManager
    class ProcessNotFound < RuntimeError; end

    class Process
      attr_reader :pid
      attr_accessor :struct

      def initialize(process_id, host_name)
        @host_name = host_name
        @pid = process_id
      end

      def send_signal(sig)
        echo_rosh_command sig

        adapter.send_signal(sig)
      end

      private

      def adapter
        return @adapter if @adapter

        type = if current_host.local?
                 :local
               else
                 :remote
        end

        @adapter = ProcessManager::ObjectAdapter.new(@pid, type, @host_name)
      end
    end
  end
end
