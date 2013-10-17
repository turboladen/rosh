require 'time'
require_relative 'base'


class Rosh
  class Users
    module ObjectAdapters
      class Unix
        include Base

        class << self
          def age
            Time.now - change
          end

          def change
            result = current_shell.exec "chage --list #{@user_name} | grep 'Last password change'"
            date = result.split(': ').last

            Time.parse(date)
          end

          # @todo Figure out what this should return.
          def comment

          end

          def dir
            getent[:dir]
          end

          def expire
            result = current_shell.exec "chage --list #{@user_name} | grep 'Account expires'"
            date = result.split(': ').last

            date.strip == 'never' ? nil : Time.parse(date)
          end

          def gecos
            getent[:gecos]
          end

          def gid
            result = current_shell.exec "id --group #{@user_name}"

            result.to_i
          end

          def info
            getent
          end

          def name
            result = current_shell.exec "id --user --name #{@user_name}"

            result.strip
          end

          def passwd
            getent[:passwd]
          end

          # @todo Figure out what this should return.
          def quota

          end

          def shell
            getent[:shell]
          end

          def uid
            result = current_shell.exec "id --user #{@user_name}"

            result.to_i
          end


          private

          def getent
            result = current_shell.exec "getent passwd #{@user_name}"
            result_split = result.split(':')

            {
              name: result_split[0],
              passwd: result_split[1],
              uid: result_split[2].to_i,
              gid: result_split[3].to_i,
              gecos: result_split[4],
              dir: result_split[5],
              shell: result_split[6].strip
            }
          end
        end
      end
    end
  end
end
