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
          result = system(@cmd)

          status = result ? 0 : 1

          ::Rosh::CommandResult.new(result, status)
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
