require_relative '../command'
require 'open4'


class Rosh
  module BuiltinCommands
    class Exec < Command
      def initialize(cmd)
        @cmd = cmd.strip
        description = "Running shell command: #{@cmd}"

        super(description)
      end

      def local_execute
        proc do
          begin
            pid, stdin, stdout, stderr = Open4.popen4(@cmd)
            _, status = Process.waitpid2 pid

            puts "pid: #{pid}"
            puts "status: #{status.inspect}"
            puts "exitstatus: #{status.exitstatus}"

            if status.exitstatus == 0
              ::Rosh::CommandResult.new(stdout.read, 0)
            else
              ::Rosh::CommandResult.new(stderr.read, status.exitstatus)
            end
          rescue => ex
            ::Rosh::CommandResult.new(ex, 1)
          end
        end
      end

      def remote_execute
        proc do |ssh|
          ssh.run @cmd
        end
      end
    end
  end
end
