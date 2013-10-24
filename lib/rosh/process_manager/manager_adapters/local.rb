require 'sys/proctable'
require_relative 'base'


class Rosh
  class ProcessManager
    module ManagerAdapters
      class Local
        include Base

        class << self

          # @param [String] name The name of a command to filter on.
          # @param [Integer] pid The pid of a command to find.
          #
          # @return [Array<Struct::ProcTableStruct>, Struct::ProcTableStruct] When
          #   no options are given, all processes returned.  When +:name+ is given,
          #   an Array of processes that match COMMAND are given.  When +:pid+ is
          #   given, a single process is returned.  See https://github.com/djberg96/sys-proctable
          #   for more info.
          def list_running(name: nil, pid: nil)
            ps = Sys::ProcTable.ps

            if name
              ps.find_all { |i| i.cmdline =~ /\b#{name}\b/ }
            elsif pid
              ps.find { |i| i.pid == pid }
            else
              ps
            end
          end
        end
      end
    end
  end
end
