class Rosh
  class Host
    module ServiceTypes
      class SystemV
        def initialize(name, host, status=nil, pid=nil)
          super(name, host, status, pid)
        end

        def start
          result = @host.shell.exec("service #{@name} status")

          if result.exit_status.zero?
            result.ruby_object =~ /^(?<script>\S+)\s+(?<status>\S+),\s+process (?<pid>\d+)/

            status = if $~
              $~[:status]
            elsif process.ruby_object
              :running
            else
              :stopped
            end

            obj = {
              name: @name,
              status: status,
              processes: process.ruby_object
            }
            obj = build_status(status, @pid)

            Rosh::CommandResult.new(obj, 0, result.ssh_result)
          elsif result.ruby_object =~ /could not access PID file for/
            Rosh::CommandResult.new(Rosh::InaccessiblePIDFile.new(result.ruby_object),
              result.exit_status, result.ssh_result)
          elsif result.exit_status == 2
            process = @host.shell.ps(@name)

            obj = {
              script: @name,
              status: result.ruby_object,
              processes: process.ruby_object
            }

            Rosh::CommandResult.new(obj, 0, result.ssh_result)
          elsif result.ruby_object =~ /Permission denied/i
            Rosh::CommandResult.new(Rosh::PermissionDenied.new(result.ruby_object),
              result.exit_status, result.ssh_result)
          else
            Rosh::CommandResult.new(Rosh::UnrecognizedService.new(result.ruby_object),
              result.exit_status, result.ssh_result)
          end
        end
      end
    end
  end
end
