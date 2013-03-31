require_relative '../command'


class Rosh
  module BuiltinCommands
    class History < Command
      DESCRIPTION = 'Shows a list of all commands that have been executed.'

      def initialize(history_array)
        super(DESCRIPTION)

        @history_array = history_array
      end

      def local_execute
        proc do
          lines = {}

          @history_array.each_with_index do |cmd, i|
            lines[i] = cmd
          end

          ::Rosh::CommandResult.new(Hash[lines.sort], 0)
        end
      end

      def remote_execute
        proc do |ssh|
          ssh.run 'history'
        end
      end
    end
  end
end

