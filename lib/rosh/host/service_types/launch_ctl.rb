require 'plist'
require_relative 'base'


class Rosh
  class Host
    module ServiceTypes
      class LaunchCTL < Base
        def initialize(name, shell, pid=nil)
          super(name, shell, pid)
        end

        def info
          state, exit_code, result, pid = fetch_status
          info = build_info(state, pid: pid)
          info[:plist] = Plist.parse_xml(result.ruby_object)

          Rosh::CommandResult.new(info, exit_code, result.ssh_result)
        end

        # :running, :stopped, :unknown, or Rosh::UnrecognizedService.
        def status
          state, exit_code, result, = fetch_status

          Rosh::CommandResult.new(state, exit_code, result.ssh_result)
        end

        def start
          result = @shell.exec("launchctl load #{@name}")

          if result.ruby_object =~ /noting found to load/m
            return Rosh::CommandResult.new(Rosh::UnrecognizedService.new(result.ruby_object),
              result.exit_status, result.ssh_result)
          end

          result
        end

        private

        # @return [Integer,nil]
        def fetch_pid
          pid_result = @shell.exec("launchctl list | grep #{@name}")
          temp_pid = pid_result.ruby_object.match /^\d+/
          temp_pid.to_s.to_i if temp_pid
        end

        # @return Array[Symbol, Integer, Rosh::CommandResult, Integer]
        def fetch_status
          result = @shell.exec("launchctl list -x #{@name}")
          pid = @pid || fetch_pid

          if result.exit_status.zero? && pid
            [:running, 0, result, pid]
          elsif result.exit_status.zero?
            [:stopped, 0, result, pid]
          elsif result.ruby_object =~ /launchctl list returned unknown response/
            [:unknown, result.exit_status, result, pid]
          else
            [Rosh::UnrecognizedService.new(result.ruby_object),
              result.exit_status, result, pid]
          end
        end
      end
    end
  end
end
