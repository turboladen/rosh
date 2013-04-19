require_relative '../../command_result'
require_relative 'base'


class Rosh
  class Host
    module ServiceTypes
      class Init < Base
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

        def info
          state, exit_code, result, pid = fetch_status

          info = if pid.is_a? Array
            build_info(state, process_info: pid)
          else
            build_info(state, pid: pid)
          end

          Rosh::CommandResult.new(info, exit_code, result.stdout, result.stderr)
        end

        def status
          state, exit_code, result, = fetch_status

          Rosh::CommandResult.new(state, exit_code, result.stdout, result.stderr)
        end

        def start
          result = @shell.exec("#{@script_dir}/#{@name} start")

          if result.exit_status.zero?
            if permission_denied? result.ruby_object
              Rosh::CommandResult.new(Rosh::PermissionDenied.new(result.ruby_object),
                result.exit_status, result.stdout, result.stderr)
            else
              result
            end
          elsif result.exit_status == 127
            Rosh::CommandResult.new(Rosh::UnrecognizedService.new(result.ruby_object),
              result.exit_status, result.stdout, result.stderr)
          elsif permission_denied? result.ruby_object
            Rosh::CommandResult.new(Rosh::PermissionDenied.new(result.ruby_object),
              result.exit_status, result.stdout, result.stderr)
          else
            result
          end
        end

        private

        def permission_denied?(output)
          if output.match(/superuser access required/) ||
            output.match(/permission denied/i)
            true
          else
            false
          end
        end

        def status_command
          case @os_type
          when :linux
            'status'
          when :freebsd
            'onestatus'
          end
        end

        def fetch_status
          result = @shell.exec("#{@script_dir}/#{@name} #{status_command}")

          if result.exit_status.zero?
            pid = fetch_pid
            state = pid.empty? ? :stopped : :running

            [state, 0, result, pid]
          elsif result.exit_status == 127
            [Rosh::UnrecognizedService.new(result.ruby_object),
              result.exit_status, result, nil]
          else
            if result.ruby_object =~ / stopped/
              [:stopped, result.exit_status, result, nil]
            else
              [:unknown, result.exit_status, result, nil]
            end
          end
        end

        # @todo fix sudo prompt!
        # @return [Array<Integer>] An Array of pids that match the name of the
        #   service.
        def fetch_pid
          process_list = @shell.ps(name: @name).ruby_object
          pids = process_list.map { |process| process.pid }

          pids
        end
      end
    end
  end
end
