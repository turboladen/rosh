require 'plist'
require_relative 'base'


class Rosh
  class Host
    module ServiceTypes
      class LaunchCTL < Base
        def initialize(name, shell, pid=nil)
          super(name, shell, pid)
        end

        # @return [Rosh::CommandResult] #ruby_object is a Hash containing +:name+
        #   +:status+, +:processes+, and +:plist+; #exit_code is 0.
        def info
          state, exit_code, result, pid = fetch_status
          info = build_info(state, pid: pid)
          info[:plist] = Plist.parse_xml(result.ruby_object)

          Rosh::CommandResult.new(info, exit_code, result.stdout, result.stderr)
        end

        # @return [Rosh::CommandResult] #ruby_object is a Symbol: +:running+,
        #   +:stopped+, +:unknown+, or is a Rosh::UnrecognizedService.
        def status
          state, exit_code, result, = fetch_status

          Rosh::CommandResult.new(state, exit_code, result.stdout, result.stderr)
        end

        # Runs `launchctl load` on the current service.
        #
        # @return [Rosh::CommandResult] If the output of the command includes
        #   'nothing found to load', a Rosh::UnrecognizedService error is
        #   returned.
        def start
          result = @shell.exec("launchctl load #{@name}")

          if result.ruby_object =~ /nothing found to load/m
            return Rosh::CommandResult.new(Rosh::UnrecognizedService.new(result.ruby_object),
              result.exit_status, result.stdout, result.stderr)
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
