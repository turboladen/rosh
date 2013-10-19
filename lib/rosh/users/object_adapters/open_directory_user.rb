require 'plist'
require_relative 'base_user'


class Rosh
  class Users
    module ObjectAdapters
      class OpenDirectoryUser
        include BaseUser

        class << self
          def exists?
            cmd = "dscl . -read /Users/#{@user_name}"
            current_shell.exec cmd

            current_shell.last_exit_status.zero?
          end

          def info
            @info ||= get_info
          end

          def gid
            cmd = "dscl plist . -read /Users/#{@user_name} PrimaryGroupID"
            output = current_shell.exec cmd

            Plist.parse_xml(output)['dsAttrTypeStandard:PrimaryGroupID'].to_i
          end

          def home_directory
            cmd = "dscl -plist . -read /Users/#{@user_name} NFSHomeDirectory"
            output = current_shell.exec cmd

            Plist.parse_xml(output)['dsAttrTypeStandard:NFSHomeDirectory']
          end

          def real_name
            cmd = "dscl . -read /Users/#{@user_name} RealName"
            output = current_shell.exec cmd

            Plist.parse_xml(output)['dsAttrTypeStandard:RealName']
          end

          def shell
            cmd = "dscl . -read /Users/#{@user_name} UserShell"
            output = current_shell.exec cmd

            Plist.parse_xml(output)['dsAttrTypeStandard:UserShell']
          end

          def uid
            cmd = "dscl . -read /Users/#{@user_name} UniqueID"
            output = current_shell.exec cmd

            Plist.parse_xml(output)['dsAttrTypeStandard:UniqueID'].to_i
          end

          def uid=(new_uid)
            cmd = "dscl . -change /Users/#{@user_name} UniqueID #{uid} #{new_uid}"
            current_shell.exec cmd

            current_shell.last_exit_status.zero?
          end

          private

          def get_info
            result = current_shell.exec "dscl -plist . -read /Users/#{@user_name}"

            Plist.parse_xml(result)
          end
        end
      end
    end
  end
end
