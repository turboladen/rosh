require 'etc'


class Rosh
  class UserManager
    module ObjectAdapters
      module LocalUser
        def age
          passwd = info_by_name

          passwd.respond_to?(:age) ? passwd.age : nil
        end

        def change
          passwd = info_by_name

          return nil unless passwd.respond_to?(:change)
          return passwd.change if passwd.change.zero?

          Time.at(passwd.change)
        end

        # @todo Implement create for local user
        def create
          warn 'Not implemented'
        end

        def comment
          passwd = info_by_name

          passwd.respond_to?(:comment) ? passwd.comment : nil
        end

        def dir
          info_by_name.dir
        end

        def exists?
          begin
            info_by_name
          rescue
            return false
          end

          true
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

        def shell
          info_by_name.shell
        end

        def uid
          info_by_name.uid
        end

        private

        def info_by_name
          ::Etc.getpwnam(@name)
        end

        def dir=(new_dir)
          warn 'Not implemented!'
        end

        def gid=(new_gid)
          warn 'Not implemented!'
        end

        def name=(new_name)
          warn 'Not implemented!'
        end

        def passwd=(new_password)
          warn 'Not implemented!'
        end

        def real_name=(new_name)
          warn 'Not implemented!'
        end

        def shell=(new_shell)
          warn 'Not implemented!'
        end

        def uid=(new_uid)
          warn 'Not implemented!'
        end
      end
    end
  end
end
