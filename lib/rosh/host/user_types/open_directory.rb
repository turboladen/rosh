require 'plist'

class Rosh
  class Host
    module UserTypes
      class OpenDirectory
        def initialize(name, host_label)
          @name = name
          @host_label = host_label
        end

        def info
          result = current_shell.exec "dscl -plist . -read /Users/#{@name}"

          Plist.parse_xml(result)
        end
      end
    end
  end
end
