require 'plist'

class Rosh
  class Host
    module GroupTypes
      module OpenDirectory
        def info
          result = current_shell.exec "dscl -plist . -read /Groups/#{@name}"

          Plist.parse_xml(result)
        end
      end
    end
  end
end
