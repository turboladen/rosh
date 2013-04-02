require_relative '../command'


class Rosh
  module BuiltinCommands
    class Pwd < Command
      DESCRIPTION = 'Displays the current working directory.'

      def initialize(force=false)
        super(DESCRIPTION)

        @force = force
      end

      def local_execute
        ::Rosh::CommandResult.new(ENV['PWD'], 0)
      end

      def remote_execute
        pwd = if @force
          result = Rosh::Environment.current_host.ssh.run 'pwd'

          unless result.ssh_result.stdout.empty?
            result.ssh_result.stdout
          end
        else
          ::Rosh::Environment.current_host.shell.env[:pwd]
        end

        ::Rosh::CommandResult.new(pwd, 0)
      end
    end
  end
end
