require_relative '../user'


class Rosh
  class UserManager
    module ObjectAdapters
      module UnixGroup
        def create
          current_shell.exec_internal "groupadd #{@name}"

          current_shell.last_exit_status.zero?
        end

        def delete
          current_shell.exec_internal "groupdel #{@name}"

          current_shell.last_exit_status.zero?
        end

        def exists?
          current_shell.exec_internal "id -g #{@name}"

          current_shell.last_exit_status.zero?
        end

        def gid
          result = current_shell.exec_internal "getent group #{@name} | cut -d: -f3"

          result.to_i
        end

        def members
          result = current_shell.exec_internal "getent group #{@name} | cut -d: -f4"

          result.split(',').map do |user_name|
            UserManager::User.new(user_name, @host_name)
          end
        end

        def name
          current_shell.exec_internal "getent group #{@name} | cut -d: -f1"
        end

        def passwd
          current_shell.exec_internal "getent group #{@name} | cut -d: -f2"
        end
      end
    end
  end
end
