require_relative 'user_manager/object'
require_relative 'user_manager/group'
require_relative 'user_manager/user'
require_relative 'user_manager/manager_adapter'

class Rosh
  class UserManager
    #     def self.create(name, host_name)
    #       object = new(host_name)
    #
    #       if object.open_directory?
    #         object.open_directory(name)
    #       else
    #         raise "Don't know what to do with #{name}"
    #       end
    #     end

    def initialize(host_name)
      @host_name = host_name
    end

    def [](name)
      result = if name.is_a? Hash
                 if name[:user]
                   user(name[:user])
                 elsif name[:group]
                   group(name[:group])
                 else
                   fail "Not sure what '#{name}' is."
                 end
               else
                 if user?(name)
                   user name
                 elsif group?(name)
                   group name
                 else
                   object name
                 end
      end

      result.add_observer(self)

      result
    end

    def group(name)
      Rosh::UserManager::Group.new(name, @host_name)
    end

    def group?(name)
      adapter.group?(name)
    end

    def list_groups
      echo_rosh_command

      adapter.groups
    end

    def list_users
      echo_rosh_command

      adapter.users
    end

    def object(name)
      Rosh::UserManager::Object.new(name, @host_name)
    end

    def user(name)
      Rosh::UserManager::User.new(name, @host_name)
    end

    def user?(name)
      adapter.user?(name)
    end

    private

    def adapter
      return @adapter if @adapter

      type = if current_host.local?
               :local
             else
               if current_host.darwin?
                 :open_directory
               else
                 :unix
               end
      end

      @adapter = UserManager::ManagerAdapter.new(type, @host_name)
    end
  end
end
