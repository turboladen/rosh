require_relative '../command'


class Rosh
  module BuiltinCommands
    class Pwd < Command
      DESCRIPTION = 'Displays the current working directory.'

      def initialize
        super(DESCRIPTION)
      end

      def local_execute
        proc do
          ::Rosh::CommandResult.new(Dir.pwd, 0)
        end
      end

      def remote_execute
        proc do |ssh|
          ssh.run 'pwd'
        end
      end
    end
  end
end
