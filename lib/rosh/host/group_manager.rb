require 'plist'
require_relative 'group'


class Rosh
  class Host
    class GroupManager
      def initialize(host)
        @host = host
      end

      def [](group_name)
        create(group_name)
      end

      def list
        result = @host.shell.exec 'dscl -plist . -readall /Groups'
        groups = Plist.parse_xml(result)

        Rosh::CommandResult.new(groups, 0, result)
      end

      private

      def create(name)
        Rosh::Host::Group.new(@host, name)
      end
    end
  end
end
