require_relative '../changeable'
require_relative '../observable'


class Rosh
  class ProcessManager
    class ProcessNotFound < RuntimeError; end

    class Process
      include Rosh::Changeable
      include Rosh::Observable


      attr_reader :id
      attr_accessor :struct

      def initialize(process_id, host_name)
        @host_name = host_name
        @id = process_id
      end


      def send_signal(sig)
        signal_name = Rosh::ProcessManager::Signal.find(sig)
        puts "signal: #{signal_name}"
        #adapter.send(signal_name)
      end
    end
  end
end
