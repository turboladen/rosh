require 'sys/proctable'
require_relative '../command'


class Rosh
  module BuiltinCommands
    class Ps < Command
      DESCRIPTION = 'Lists currently running processes and info about them.'

      def initialize
        super(DESCRIPTION)
      end

      # @return [Hash{Fixnum => Struct::ProcTableStruct}]
      def local_execute
        r = Sys::ProcTable.ps.inject({}) do |result, p|
          result[p.pid] = p

          result
        end

        ::Rosh::CommandResult.new(Hash[r.sort], 0)
      end

      def remote_execute
        Rosh::Environment.current_host.ssh.run 'ps -aux'
      end
    end
  end
end
