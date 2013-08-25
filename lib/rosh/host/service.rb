require 'observer'
require_relative '../string_refinements'


class Rosh
  class Host
    class Service
      attr_reader :name
      attr_reader :status

      def initialize(type, name, host_name, pid=nil)
        @host_name = host_name
        @name = name
        @status = nil
        @pid = pid

        load_strategy(type)
      end

      def info
        warn 'Implement in child.'
      end

      def status
        warn 'Implement in child.'
      end

      def start
        warn 'Implement in child.'
      end

      #-------------------------------------------------------------------------
      # PRIVATES
      #-------------------------------------------------------------------------
      private

      # Loads the adapter object based on the given +type+.
      #
      # @param [Symbol, String] type
      def load_strategy(type)
        require_relative "service_types/#{type}"
        service_klass = Rosh::Host::ServiceTypes.const_get(type.to_s.classify)

        extend service_klass
      end

      def build_info(status, pid: nil, process_info: nil)
        process_info = if pid
          current_shell.ps(pid: pid)
        elsif process_info
          process_info
        else
          current_shell.ps(name: @name)
        end

        if pid && !process_info.empty?
          status = :running
        end

        {
          name: @name,
          status: status,
          processes: process_info
        }
      end
    end
  end
end
