require_relative '../user'
require_relative '../group'

class Rosh
  class UserManager
    module ManagerAdapters
      module Unix
        def groups
          list = current_shell.exec_internal 'getent group | cut -d: -f1'

          list.split.map do |name|
            Rosh::UserManager::Group.new(name, @host_name)
          end
        end

        def group?(name)
          current_shell.exec_internal %(getent group | grep #{name})

          current_shell.last_exit_status.zero?
        end

        def users
          list = current_shell.exec_internal 'getent passwd | cut -d: -f1'

          list.split.map do |name|
            Rosh::UserManager::User.new(name, @host_name)
          end
        end

        def user?(name)
          current_shell.exec_internal %(id #{name})

          current_shell.last_exit_status.zero?
        end
      end
    end
  end
end
