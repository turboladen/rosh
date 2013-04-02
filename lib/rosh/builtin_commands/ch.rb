require_relative '../command'
require_relative '../environment'


class Rosh
  module BuiltinCommands
    class Ch < Command
      def initialize(hostname='localhost')
        @hostname = hostname.strip
        description = "Changing current working host to '#{@hostname}'"
        super(description)
      end

      def local_execute
        host = Rosh::Environment.hosts[@hostname]

        host.nil? ? [1, "No host defined for #{@hostname}"] : [0, host]
      end
    end
  end
end
