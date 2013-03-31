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
=begin
          begin
            pid, stdin, stdout, stderr = Open4.popen4(@cmd)
            _, status = Process.waitpid2 pid


            out = stdout.read
            err = stderr.read
            puts "pid: #{pid}"
            puts "status: #{status.inspect}"
            puts "exitstatus: #{status.exitstatus}"

            if status.exitstatus == 0
              puts out
              ::Rosh::CommandResult.new(out, 0)
            else
              puts err
              ::Rosh::CommandResult.new(err, status.exitstatus)
            end
          rescue => ex
            ::Rosh::CommandResult.new(ex, 1)
          end
=end
          result = system(@cmd)

          ::Rosh::CommandResult.new(result, 0)
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
