require_relative '../command'
require 'pty'


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
          result = ''

          begin
            PTY.spawn(@cmd) do |stdin, stdout, pid|
              begin
                stdin.each { |line| print line; result << line }
              rescue Errno::EIO
                puts "Errno:EIO error, but this probably just means " +
                  "that the process has finished giving output"
              end
            end
          rescue PTY::ChildExited
            puts 'The child process exited!'
          end

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
