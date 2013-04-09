require 'plist'
require_relative '../errors'


class Rosh
  class Host
    class Service
      def initialize(name, host)
        @name = name
        @host = host
      end

      def status
        case @host.operating_system
        when :darwin
          process_darwin
        when :linux
          result = @host.shell.exec("service #{@name} status")

          if result.ruby_object =~ /service: command not found/
            process_linux_initd
          else
            process_linux_service(result)
          end
        end
      end

      private

      def process_darwin
        result = @host.shell.exec("launchctl list -x #{@name}")

        if result.exit_status.zero?
          Rosh::CommandResult.new(Plist.parse_xml(result.ruby_object), 0,
            result.ssh_result)
        else
          Rosh::CommandResult.new(Rosh::UnrecognizedService.new(result.ruby_object),
            result.exit_status, result.ssh_result)
        end
      end

      def process_linux_service(result)
        if result.exit_status.zero?
          result.ruby_object =~ /^(?<script>\S+)\s+(?<status>\S+),\s+process (?<pid>\d+)/
          process = @host.shell.ps(@name)

          status = if $~
            $~[:status]
          elsif process.ruby_object
            'running'
          else
            'not running'
          end

          obj = {
            script: @name,
            status: status,
            process: process.ruby_object
          }

          Rosh::CommandResult.new(obj, 0, result.ssh_result)
        elsif result.ruby_object =~ /could not access PID file for/
          Rosh::CommandResult.new(Rosh::InaccessiblePIDFile.new(result.ruby_object),
            result.exit_status, result.ssh_result)
        else
          Rosh::CommandResult.new(Rosh::UnrecognizedService.new(result.ruby_object),
            result.exit_status, result.ssh_result)
        end
      end

      def process_linux_initd
        result = @host.shell.exec("/etc/init.d/#{@name} status")

        if result.exit_status.zero?
          result.ruby_object =~ /^(?<script>\S+) is (?<status>\S+)/
          process = @host.shell.ps(@name)

          status = if $~
            $~[:status]
          elsif process.ruby_object
            'running'
          else
            'not running'
          end

          obj = {
            script: @name,
            status: status,
            process: process.ruby_object
          }

          Rosh::CommandResult.new(obj, 0, result.ssh_result)
        elsif result.exit_status == 127
          Rosh::CommandResult.new(Rosh::UnrecognizedService.new(result.ruby_object),
            result.exit_status, result.ssh_result)
        else
          process = @host.shell.ps(@name)

          obj = {
            script: @name,
            status: 'not running',
            process: process.ruby_object
          }

          Rosh::CommandResult.new(obj, result.exit_status, result.ssh_result)
        end
      end
    end
  end
end
