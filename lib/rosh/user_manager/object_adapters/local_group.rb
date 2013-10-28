require 'etc'
require_relative '../user'


class Rosh
  class UserManager
    module ObjectAdapters
      module LocalGroup
        def exists?
          warn 'Not implemented.'
        end

        def gid
          info_by_name.gid
        end

        def members
          info_by_name.mem.map do |user_name|
            UserManager::User.new(user_name, @host_name)
          end
        end

        def name
          info_by_name.name
        end

        def passwd
          info_by_name.passwd
        end

        private

        def info_by_name
          ::Etc.getgrnam(@group_name)
        end
      end
    end
  end
end
