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
      def execute
        r = Sys::ProcTable.ps.inject({}) do |result, p|
          result[p.pid] = p

          result
        end

        [0, Hash[r.sort]]
      end
    end
  end
end
