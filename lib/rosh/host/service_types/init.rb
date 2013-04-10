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

          Rosh::CommandResult.new(info, exit_code, result.ssh_result)
        end

        def status
          state, exit_code, result, = fetch_status

          Rosh::CommandResult.new(state, exit_code, result.ssh_result)
        end

        private

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
            pid, state = fetch_pid

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
        def fetch_pid
          #pid = @host.shell.exec("sudo cat /var/run/#{@name}.pid").ruby_object
          pid = nil

          state = if pid
            pid = pid.to_i
            :running
          else
            process_list = @shell.ps(name: @name).ruby_object

            if process_list.empty?
              :stopped
            else
              pid = process_list
              :running
            end
          end

          [pid, state]
        end
      end
    end
  end
end
