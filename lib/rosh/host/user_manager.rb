require 'plist'
require_relative 'user'


class Rosh
  class Host
    class UserManager
      def initialize(host)
        @host = host
      end

      def [](user_name)
        create(user_name)
      end

      def list
        result = @host.shell.exec 'dscl -plist . -readall /Users'
        users = Plist.parse_xml(result.ruby_object)

        Rosh::CommandResult.new(users, 0, result.stdout, result.stderr)
      end

      private

      def create(name)
        Rosh::Host::User.new(@host, name)
      end
    end
  end
end
