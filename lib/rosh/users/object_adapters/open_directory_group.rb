require 'plist'
require_relative 'base_group'
require_relative '../user'


class Rosh
  class Users
    module ObjectAdapters
      class OpenDirectoryGroup
        include BaseGroup

        class << self
          def gid
            cmd = "dscl -plist . -read /Groups/#{@group_name} PrimaryGroupID"
            output = current_shell.exec cmd

            if output =~ /eDSRecordNotFound/
              raise Rosh::Users::GroupNotFound, "Group not found: #{@group_name}"
            else
              Plist.parse_xml(output)['dsAttrTypeStandard:PrimaryGroupID'].first.to_i
            end
          end

          def members
            cmd = "dscl -plist . -read /Groups/#{@group_name} GroupMembership"
            output = current_shell.exec cmd

            if output =~ /eDSRecordNotFound/
              raise Rosh::Users::GroupNotFound, "Group not found: #{@group_name}"
            else
              Plist.parse_xml(output)['dsAttrTypeStandard:GroupMembership'].map do |user_name|
                Rosh::Users::User.new(user_name, @host_name)
              end
            end
          end

          def name
            cmd = "dscl -plist . -read /Groups/#{@group_name} RecordName"
            output = current_shell.exec cmd

            if output =~ /eDSRecordNotFound/
              raise Rosh::Users::GroupNotFound, "Group not found: #{@group_name}"
            else
              Plist.parse_xml(output)['dsAttrTypeStandard:RecordName'].first
            end
          end

          def passwd
            cmd = "dscl -plist . -read /Groups/#{@group_name} Password"
            output = current_shell.exec cmd

            if output =~ /eDSRecordNotFound/
              raise Rosh::Users::GroupNotFound, "Group not found: #{@group_name}"
            else
              Plist.parse_xml(output)['dsAttrTypeStandard:Password'].first
            end
          end
        end
      end
    end
  end
end
