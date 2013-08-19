require_relative '../../command_result'
require_relative 'base'


class Rosh
  class Host
    module ServiceTypes
      class Init < Base

        # @param [String] name
        # @param [Rosh::Host::Shells::*] shell
        # @param [Symbol] os_type
        # @param [Number] pid
        def initialize(name, shell, os_type, pid=nil)
          super(name, shell, pid)

          @shell = shell
          @os_type = os_type

          @script_dir = case @os_type
          when :linux
            '/etc/init.d'
          when :freebsd
            '/etc/rc.d'
          end
        end

        # @return [Hash{name: String, status: Symbol, processes: Fixnum}]
        def info
          state = fetch_status
          pid = fetch_pid

          info = if pid.is_a? Array
            build_info(state, process_info: pid)
          else
            build_info(state, pid: pid)
          end

          info
        end

        # @return [Symbol]
        def status
          result = @shell.exec("#{@script_dir}/#{@name} #{status_command}")

          if @shell.last_exit_status.zero?
            pid = fetch_pid
            pid.empty? ? :stopped : :running
          elsif @shell.last_exit_status == 127
            :unrecognized_service
          else
            if result =~ / stopped/
              :stopped
            else
              :unknown
            end
          end
        end

        # Starts the service.
        #
        # @return [Boolean] +true+ if successful, +false+ if not.
        def start
          @shell.exec("#{@script_dir}/#{@name} start")

          @shell.last_exit_status.zero?
        end

        # Starts the service, but raises if not able to.
        #
        # @return [NilClass]
        # @raise [Rosh::PermissionDenied]
        # @raise [Rosh::UnrecognizedService]
        def start!
          result = @shell.exec("#{@script_dir}/#{@name} start")

          if @shell.last_exit_status.zero?
            if permission_denied? result
              raise Rosh::PermissionDenied, result
            end
          elsif @shell.last_exit_status == 127
            raise Rosh::UnrecognizedService, result
          elsif permission_denied? result
            raise Rosh::PermissionDenied, result
          end
        end

        private

        # Determines from +output+ if the message contains text that represents
        # a permission denied error.
        #
        # @param [String] output
        # @return [Boolean]
        def permission_denied?(output)
          if output.match(/superuser access required/) ||
            output.match(/permission denied/i)
            true
          else
            false
          end
        end

        # Command used for getting service status, based on OS.
        #
        # @return [String]
        def status_command
          case @os_type
          when :linux
            'status'
          when :freebsd
            'onestatus'
          end
        end

        # @return [Array<Integer>] An Array of pids that match the name of the
        #   service.
        def fetch_pid
          process_list = @shell.ps(name: @name)
          pids = process_list.map { |process| process.pid }

          pids
        end
      end
    end
  end
end
