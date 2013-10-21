require 'plist'
require_relative 'base_user'


class Rosh
  class UserManager
    module ObjectAdapters
      class OpenDirectoryUser
        include BaseUser

        class << self
          def age
            warn 'Not implemented!'
          end

          def change
            warn 'Not implemented!'
          end

          def dir
            cmd = "dscl -plist . -read /Users/#{@user_name} NFSHomeDirectory"
            output = current_shell.exec cmd

            Plist.parse_xml(output)['dsAttrTypeStandard:NFSHomeDirectory'].first
          end

          def expire
            warn 'Not implemented!'
          end

          def exists?
            cmd = "dscl . -read /Users/#{@user_name}"
            current_shell.exec cmd

            current_shell.last_exit_status.zero?
          end

          def gid
            cmd = "dscl -plist . -read /Users/#{@user_name} PrimaryGroupID"
            output = current_shell.exec cmd

            Plist.parse_xml(output)['dsAttrTypeStandard:PrimaryGroupID'].first.to_i
          end

          def info
            @info ||= get_info
          end

          def name
            cmd = "dscl -plist . -read /Users/#{@user_name} RecordName"
            output = current_shell.exec cmd

            Plist.parse_xml(output)['dsAttrTypeStandard:RecordName'].first
          end

          def passwd
            cmd = "dscl -plist . -read /Users/#{@user_name} Password"
            output = current_shell.exec cmd

            Plist.parse_xml(output)['dsAttrTypeStandard:Password'].first
          end

          def real_name
            cmd = "dscl -plist . -read /Users/#{@user_name} RealName"
            output = current_shell.exec cmd

            Plist.parse_xml(output)['dsAttrTypeStandard:RealName'].first
          end

          def shell
            cmd = "dscl -plist . -read /Users/#{@user_name} UserShell"
            output = current_shell.exec cmd

            Plist.parse_xml(output)['dsAttrTypeStandard:UserShell'].first
          end

          def uid
            cmd = "dscl -plist . -read /Users/#{@user_name} UniqueID"
            output = current_shell.exec cmd

            Plist.parse_xml(output)['dsAttrTypeStandard:UniqueID'].first.to_i
          end

          private

          def get_info
            result = current_shell.exec "dscl -plist . -read /Users/#{@user_name}"

            Plist.parse_xml(result)
          end

          def dir=(new_dir)
            cmd = %[dscl -plist . -change /Users/#{@user_name} NFSHomeDirectory "#{dir}" "#{new_dir}"]
            current_shell.exec cmd

            current_shell.last_exit_status.zero?
          end

          def gid=(new_gid)
            cmd = %[dscl -plist . -change /Users/#{@user_name} PrimaryGroupID #{gid} #{new_gid}]
            current_shell.exec cmd

            current_shell.last_exit_status.zero?
          end

          def name=(new_name)
            cmd = %[dscl -plist . -change /Users/#{@user_name} RecordName #{name} #{new_name}]
            current_shell.exec cmd

            current_shell.last_exit_status.zero?
          end

          def passwd=(new_password)
            cmd = %[dscl -plist . -change /Users/#{@user_name} Password "#{passwd}" "#{new_password}"]
            current_shell.exec cmd

            current_shell.last_exit_status.zero?
          end

          def real_name=(new_name)
            cmd = %[dscl -plist . -change /Users/#{@user_name} RealName "#{real_name}" "#{new_name}"]
            current_shell.exec cmd

            current_shell.last_exit_status.zero?
          end

          def shell=(new_shell)
            cmd = %[dscl -plist . -change /Users/#{@user_name} UserShell "#{shell}" "#{new_shell}"]
            current_shell.exec cmd

            current_shell.last_exit_status.zero?
          end

          def uid=(new_uid)
            cmd = %[dscl -plist . -change /Users/#{@user_name} UniqueID #{uid} #{new_uid}]
            current_shell.exec cmd

            current_shell.last_exit_status.zero?
          end
        end
      end
    end
  end
end
