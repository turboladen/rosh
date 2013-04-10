require_relative '../errors'


class Rosh
  class Host
    class Service
      attr_reader :name
      attr_reader :pid

      def initialize(name, host, pid=nil)
        @name = name
        @host = host
        @pid = pid
      end

      # Each call returns a CommandResult, where the #ruby_object is a
      # Hash that always contains three keys:
      #   * +:name+: the name of the service.
      #   * +:status+: +:running+, +:stopped+
      #   * +:processes+: an Array of processes that match the service name.
      #
      # ...although, depending on the host OS, may contain other info.  OS X, for
      # example, will include +:plist+, which is the result of `launchctl list -x
      # [name]`.
      def info
        warn 'Implement in child.'
      end

      def status
        warn 'Implement in child.'
      end

      def start
        warn 'Implement in child.'
      end

      private

      def build_info(status, pid: nil, process_info: nil)
        process_info = if pid
          @host.shell.ps(pid: pid).ruby_object
        elsif process_info
          process_info
        else
          @host.shell.ps(name: @name).ruby_object
        end

        if pid && process_info
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
