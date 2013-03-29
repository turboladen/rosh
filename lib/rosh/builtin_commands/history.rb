require 'readline'
require_relative '../command'


class Rosh
  module BuiltinCommands
    class History < Command
      DESCRIPTION = 'Shows a list of all commands that have been executed.'

      def initialize
        super(DESCRIPTION)
      end

      def local_execute
        proc do
          lines = []

          Readline::HISTORY.to_a.each_with_index do |cmd, i|
            lines << "  #{i}  #{cmd}"
          end

          ::Rosh::CommandResult.new(lines, 0)
        end
      end

      def remote_execute
        proc do
          ssh.run 'history'
        end
      end
    end
  end
end

