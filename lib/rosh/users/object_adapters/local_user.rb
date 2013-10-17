require 'etc'
require_relative 'base'


class Rosh
  class Users
    module ObjectAdapters
      class LocalUser
        include Base

        class << self
          def age
            passwd = info_by_name

            passwd.respond_to?(:age) ? passwd.age : nil
          end

          def change
            passwd = info_by_name

            passwd.respond_to?(:change) ? Time.new(passwd.change) : nil
          end

          def comment
            passwd = info_by_name

            passwd.respond_to?(:comment) ? passwd.comment : nil
          end

          def dir
            info_by_name.dir
          end

          def expire
            passwd = info_by_name

            passwd.respond_to?(:expire) ? passwd.expire : nil
          end

          def gecos
            passwd = info_by_name

            passwd.respond_to?(:gecos) ? passwd.gecos : nil
          end

          def gid
            info_by_name.gid
          end

          def info
            self.gecos
          end

          def name
            info_by_name.name
          end

          def passwd
            info_by_name.passwd
          end

          def quota
            passwd = info_by_name

            passwd.respond_to?(:quota) ? passwd.quota : nil
          end

          def shell
            info_by_name.shell
          end

          def uid
            info_by_name.uid
          end

          private

          def info_by_name
            ::Etc.getpwnam(@user_name)
          end
        end
      end
    end
  end
end
