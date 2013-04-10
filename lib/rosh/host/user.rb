require 'plist'


class Rosh
  class Host
    class User
      def initialize(host, name)
        @name = name
        @host = host
      end

      def info
        result = @host.shell.exec "dscl -plist . -read /Users/#{@name}"
        user = Plist.parse_xml(result.ruby_object)

        Rosh::CommandResult.new(user, 0, result.ssh_result)
      end
    end
  end
end
