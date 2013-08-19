require 'plist'


class Rosh
  class Host
    class Group
      def initialize(host, name)
        @name = name
        @host = host
      end

      def info
        result = @host.shell.exec "dscl -plist . -read /Groups/#{@name}"
        group = Plist.parse_xml(result)
        group.strip!

        Rosh::CommandResult.new(group, 0, result)
      end
    end
  end
end
