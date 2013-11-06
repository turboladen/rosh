require 'plist'
require_relative '../user'


class Rosh
  class UserManager
    module ObjectAdapters
      module OpenDirectoryGroup
        def create
          cmd = "dscl . -create /Groups/#{@name}"
          current_shell.exec_internal cmd

          current_shell.last_exit_status.zero?
        end

        def delete
          cmd = "dscl . -delete /Groups/#{@name}"
          current_shell.exec_internal cmd

          current_shell.last_exit_status.zero?
        end

        def exists?
          cmd = "dscl -plist . -read /Groups/#{@name}"
          current_shell.exec_internal cmd

          current_shell.last_exit_status.zero?
        end

        def gid
          cmd = "dscl -plist . -read /Groups/#{@name} PrimaryGroupID"
          output = current_shell.exec_internal cmd

          if output =~ /eDSRecordNotFound/
            raise Rosh::UserManager::GroupNotFound, "Group not found: #{@name}"
          else
            Plist.parse_xml(output)['dsAttrTypeStandard:PrimaryGroupID'].first.to_i
          end
        end

        def members
          cmd = "dscl -plist . -read /Groups/#{@name} GroupMembership"
          output = current_shell.exec_internal cmd

          if output =~ /eDSRecordNotFound/
            raise Rosh::UserManager::GroupNotFound, "Group not found: #{@name}"
          else
            Plist.parse_xml(output)['dsAttrTypeStandard:GroupMembership'].map do |user_name|
              Rosh::UserManager::User.new(user_name, @host_name)
            end
          end
        end

        def name
          cmd = "dscl -plist . -read /Groups/#{@name} RecordName"
          output = current_shell.exec_internal cmd

          if output =~ /eDSRecordNotFound/
            raise Rosh::UserManager::GroupNotFound, "Group not found: #{@name}"
          else
            Plist.parse_xml(output)['dsAttrTypeStandard:RecordName'].first
          end
        end

        def passwd
          cmd = "dscl -plist . -read /Groups/#{@name} Password"
          output = current_shell.exec_internal cmd

          if output =~ /eDSRecordNotFound/
            raise Rosh::UserManager::GroupNotFound, "Group not found: #{@name}"
          else
            Plist.parse_xml(output)['dsAttrTypeStandard:Password'].first
          end
        end
      end
    end
  end
end
