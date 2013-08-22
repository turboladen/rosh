require 'plist'

class Rosh
  class Host
    module UserTypes
      class OpenDirectory
        def initialize(name, shell)
          @name = name
          @shell = shell
        end

        def info
          result = @shell.exec "dscl -plist . -read /Users/#{@name}"

          Plist.parse_xml(result)
        end
      end
    end
  end
end
