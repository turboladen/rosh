require 'plist'
require_relative 'base'


class Rosh
  class Users
    module ObjectAdapters
      class OpenDirectory
        include Base

        class << self
          def info
            @info ||= get_info
          end

          def gid
            cmd = "dscl . -read /Users/#{@user_name} PrimaryGroupID"
            output = current_shell.exec cmd
            %r[PrimaryGroupID: (?<group_id>\d+)] =~ output

            group_id.to_i
          end

          def home_directory
            cmd = "dscl . -read /Users/#{@user_name} NFSHomeDirectory"
            output = current_shell.exec cmd
            %r[NFSHomeDirectory: (?<home_dir>.+)\Z]m =~ output

            home_dir.strip
          end

          def real_name
            cmd = "dscl . -read /Users/#{@user_name} RealName"
            output = current_shell.exec cmd
            %r[RealName:\r\n (?<the_name>.+)\Z]m =~ output

            the_name.strip
          end

          def shell
            cmd = "dscl . -read /Users/#{@user_name} UserShell"
            output = current_shell.exec cmd
            %r[UserShell: (?<user_shell>\S+)] =~ output

            user_shell
          end

          def uid
            cmd = "dscl . -read /Users/#{@user_name} UniqueID"
            output = current_shell.exec cmd
            %r[UniqueID: (?<user_id>\d+)] =~ output

            user_id.to_i
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
