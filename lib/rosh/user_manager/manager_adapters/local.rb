require 'etc'
require_relative '../user'
require_relative '../group'


class Rosh
  class UserManager
    module ManagerAdapters
      module Local
        def groups
          groups = []

          Etc.group do |struct|
            groups << Rosh::UserManager::Group.new(struct.name, @host_name)
          end

          groups
        end

        def group?(name)
          begin
            ::Etc.getgrnam(name)
          rescue ArgumentError
            return false
          end

          true
        end

        def users
          users = []

          Etc.passwd do |struct|
            users << Rosh::UserManager::User.new(struct.name, @host_name)
          end

          users
        end

        def user?(name)
          begin
            ::Etc.getpwnam(name)
          rescue ArgumentError
            return false
          end

          true
        end
      end
    end
  end
end
