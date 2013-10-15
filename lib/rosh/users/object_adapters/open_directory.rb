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

          def gid
            info['dsAttrTypeStandard:PrimaryGroupID'].first.to_i
          end

          def home_directory
            info['dsAttrTypeStandard:NFSHomeDirectory'].first
          end

          def real_name
            info['dsAttrTypeStandard:RealName'].first
          end

          def shell
            info['dsAttrTypeStandard:UserShell'].first
          end

          def uid
            info['dsAttrTypeStandard:UniqueID'].first.to_i
          end
        end
      end
    end
  end
end
