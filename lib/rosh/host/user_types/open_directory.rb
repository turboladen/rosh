require 'plist'

class Rosh
  class Host
    module UserTypes
      module OpenDirectory
        def info
          result = current_shell.exec "dscl -plist . -read /Users/#{@name}"

          Plist.parse_xml(result)
        end
      end
    end
  end
end
