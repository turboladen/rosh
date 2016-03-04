require_relative 'user'
require_relative 'group'

class Rosh
  class UserManager
    class Object
      def initialize(object_name, host_name)
        @object_name = object_name
        @host_name = host_name
      end

      def create_group
        UserManager::Group.new(@object_name, @host_name).create
      end

      def create_user
        UserManager::User.new(@object_name, @host_name).create
      end

      def exists?
        UserManager::Group.new(@object_name, @host_name).exists? ||
          UserManager::User.new(@object_name, @host_name).exists?
      end
    end
  end
end
