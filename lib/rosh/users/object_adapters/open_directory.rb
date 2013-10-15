require 'plist'
require_relative 'base'


class Rosh
  class Users
    module ObjectAdapters
      class OpenDirectory
        include Base

        class << self
          def info
            result = current_shell.exec "dscl -plist . -read /Users/#{@name}"

            Plist.parse_xml(result)
          end
        end
      end
    end
  end
end
