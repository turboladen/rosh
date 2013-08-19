require 'plist'
require_relative 'base'


class Rosh
  class Host
    module ServiceTypes
      class LaunchCTL < Base

        # @param [String] name
        # @param [Rosh::Host::Shells::*] shell
        # @param [Fixnum] pid
        def initialize(name, shell, pid=nil)
          super(name, shell, pid)
        end

        # @return [Rosh::CommandResult] #ruby_object is a Hash containing +:name+
        #   +:status+, +:processes+, and +:plist+; #exit_code is 0.
        def info
          state, result, pid = fetch_status
          info = build_info(state, pid: pid)
          info[:plist] = Plist.parse_xml(result)

          info
        end

        # @return [Symbol] +:running+, +:stopped+, +:unknown+, or
        #   +unrecognized_service+.
        def status
          state = fetch_status.first

          state
        end

        # Runs `launchctl load` on the current service.
        #
        # @return [Boolean] +true+ if successful, +false+ if not.
        def start
          @shell.exec("launchctl load #{@name}")

          @shell.last_exit_status.zero?
        end

        # Runs `launchctl load` on the current service, but raises if it could
        # not start.
        #
        # @return [NilClass]
        # @raises [Rosh::UnrecognizedService]
        def start!
          result = @shell.exec("launchctl load #{@name}")

          if result =~ /nothing found to load/m
            raise Rosh::UnrecognizedService, result
          else
            nil
          end
        end

        private

        # @return [Integer,nil]
        def fetch_pid
          pid_result = @shell.exec("launchctl list | grep #{@name}")
          temp_pid = pid_result.match /^\d+/

          temp_pid.to_s.to_i if temp_pid
        end

        # @return [Array[Symbol, String, Integer]]
        def fetch_status
          result = @shell.exec("launchctl list -x #{@name}")
          pid = @pid || fetch_pid

          if @shell.last_exit_status.zero? && pid
            [:running, result, pid]
          elsif @shell.last_exit_status.zero?
            [:stopped, result, pid]
          elsif result =~ /launchctl list returned unknown response/
            [:unknown, result, pid]
          else
            [:unrecognized_service, result, pid]
          end
        end
      end
    end
  end
end
