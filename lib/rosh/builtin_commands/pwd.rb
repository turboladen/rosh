require_relative '../command'


class Rosh
  module BuiltinCommands
    class Pwd < Command
      DESCRIPTION = 'Displays the current working directory.'

      def initialize
        super(DESCRIPTION)
      end

      def local_execute
        ::Rosh::CommandResult.new(Dir.pwd, 0)
      end

      def remote_execute
        Rosh::Environment.current_host.ssh.run 'pwd'
      end
    end
  end
end
