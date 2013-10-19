require_relative 'base'
require_relative '../user'
require_relative '../group'


class Rosh
  class Users
    module ManagerAdapters
      class Unix
        include Base

        class << self
          def groups
            list = current_shell.exec 'getent group | cut -d: -f1'

            list.split.map do |name|
              Rosh::Users::Group.new(name, @host_name)
            end
          end

          def group?(name)
            current_shell.exec %[getent group | grep #{name}]

            current_shell.last_exit_status.zero?
          end

          def users
            list = current_shell.exec 'getent passwd | cut -d: -f1'

            list.split.map do |name|
              Rosh::Users::User.new(name, @host_name)
            end
          end

          def user?(name)
            current_shell.exec %[id #{name}]

            current_shell.last_exit_status.zero?
          end
        end
      end
    end
  end
end
