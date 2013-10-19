require_relative 'base_group'
require_relative '../user'


class Rosh
  class UserManager
    module ObjectAdapters
      class UnixGroup
        include BaseGroup

        class << self
          def gid
            result = current_shell.exec "getent group #{@group_name} | cut -d: -f3"

            result.to_i
          end

          def members
            result = current_shell.exec "getent group #{@group_name} | cut -d: -f4"

            result.split(',').map do |user_name|
              UserManager::User.new(user_name, @host_name)
            end
          end

          def name
            current_shell.exec "getent group #{@group_name} | cut -d: -f1"
          end

          def passwd
            current_shell.exec "getent group #{@group_name} | cut -d: -f2"
          end
        end
      end
    end
  end
end
