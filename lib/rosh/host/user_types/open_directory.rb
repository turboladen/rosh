require 'plist'

class Rosh
  class Host
    module UserTypes
      class OpenDirectory
        def initialize(name, host_name, uid: nil, gid: nil, dir: nil, shell: nil,
          gecos: nil
        )
          @name = name
          @host_name = host_name
          @user_id = uid.to_i
          @group_id = gid.to_i
          @home_directory = dir
          @shell = shell
          @description = gecos
        end

        def info
          result = current_shell.exec "dscl -plist . -read /Users/#{@name}"

          Plist.parse_xml(result)
        end
      end
    end
  end
end
