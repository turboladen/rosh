require 'plist'


class Rosh
  class Host
    class Service
      def initialize(name, shell, operating_system)
        @name = name
        @shell = shell
        @operating_system = operating_system
      end

      def status
        case @operating_system
        when :darwin
          result = @shell.exec("launchctl list -x #{@name}")

          Plist.parse_xml(result.ruby_object)
        end
      end
    end
  end
end
