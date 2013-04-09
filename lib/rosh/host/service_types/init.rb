class Rosh
  class Host
    module ServiceTypes
      class Init
        def initialize(name, host, status=nil, pid=nil)
          super(name, host, status, pid)
        end

        def info
          result = @host.shell.exec("/etc/init.d/#{@name} status")

          if result.exit_status.zero?
            result.ruby_object =~ /^(?<script>\S+) is (?<status>\S+)/
            process = @host.shell.ps(@name)

            status = if $~
              $~[:status]
            elsif process.ruby_object
              :running
            else
              :not_running
            end

            obj = {
              script: @name,
              status: status,
              processes: process.ruby_object
            }

            Rosh::CommandResult.new(obj, 0, result.ssh_result)
          elsif result.exit_status == 127
            Rosh::CommandResult.new(Rosh::UnrecognizedService.new(result.ruby_object),
              result.exit_status, result.ssh_result)
          else
            process = @host.shell.ps(@name)

            obj = {
              script: @name,
              status: :not_running,
              processes: process.ruby_object
            }

            Rosh::CommandResult.new(obj, result.exit_status, result.ssh_result)
          end
        end
      end
    end
  end
end
