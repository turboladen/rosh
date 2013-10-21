require_relative 'base'


class Rosh
  class ServiceManager
    module ObjectAdapters
      class Init
        include Base

        class << self
          def script_dir
            @script_dir ||= case current_host.operating_system
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
          # @todo Check for the process if 'Usage: ...' is returned.
          def status
            result = current_shell.exec("#{script_dir}/#{@service_name} #{status_command}")

            if current_shell.last_exit_status.zero?
              pid = fetch_pid
              pid.empty? ? :stopped : :running
            elsif current_shell.last_exit_status == 127
              :unrecognized_service
            else
              if result =~ / (stopped|not running)/
                :stopped
              elsif result =~ /Usage:/
                :status_command_not_supported
              else
                :unknown
              end
            end
          end

          # Starts the service.
          #
          # @return [Boolean] +true+ if successful, +false+ if not.
          def start
            current_shell.exec("#{script_dir}/#{@service_name} start")

            current_shell.last_exit_status.zero?
          end

          # Starts the service, but raises if not able to.
          #
          # @return [NilClass]
          # @raise [Rosh::PermissionDenied]
          # @raise [Rosh::UnrecognizedService]
          def start!
            result = current_shell.exec("#{script_dir}/#{@service_name} start")

            if current_shell.last_exit_status.zero?
              if permission_denied? result
                raise Rosh::PermissionDenied, result
              end
            elsif current_shell.last_exit_status == 127
              raise Rosh::UnrecognizedService, result
            elsif permission_denied? result
              raise Rosh::PermissionDenied, result
            end
          end

          def stop
            current_shell.exec("#{script_dir}/#{@service_name} stop")

            current_shell.last_exit_status.zero?
          end

          def stop!
            result = current_shell.exec("#{script_dir}/#{@service_name} stop")

            if current_shell.last_exit_status.zero?
              if permission_denied? result
                raise Rosh::PermissionDenied, result
              end
            elsif current_shell.last_exit_status == 127
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
            case current_host.operating_system
            when :linux
              'status'
            when :freebsd
              'onestatus'
            end
          end

          # @return [Array<Integer>] An Array of pids that match the name of the
          #   service.
          def fetch_pid
            process_list = current_shell.ps(name: @service_name)
            pids = process_list.map { |process| process.pid }

            pids
          end
        end
      end
    end
  end
end
