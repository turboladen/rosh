require_relative 'base'
require_relative '../user'


class Rosh
  class Users
    module ManagerAdapters
      class Unix
        include Base

        class << self
          def list
            list = current_shell.exec 'getent passwd | cut -d: -f1'
            list.split.map do |name|
              Rosh::Users::User.new(name, @host_name)
            end
          end

          def user?
            current_shell.exec "id #{@user_name}"

            current_shell.last_exit_status.zero?
          end
        end
      end
    end
  end
end
