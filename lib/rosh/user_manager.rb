require_relative 'kernel_refinements'
require_relative 'changeable'
require_relative 'observer'
require_relative 'observable'
require_relative 'user_manager/object'
require_relative 'user_manager/group'
require_relative 'user_manager/user'


class Rosh
  class UserManager
    include Rosh::Changeable
    include Rosh::Observer
    include Rosh::Observable

=begin
    def self.create(name, host_name)
      object = new(host_name)

      if object.open_directory?
        object.open_directory(name)
      else
        raise "Don't know what to do with #{name}"
      end
    end
=end

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
          raise "Not sure what '#{name}' is."
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

    def groups
      adapter.groups
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

    def users
      adapter.users
    end

    private

    def adapter
      return @adapter if @adapter

      @adapter = if current_host.local?
        require_relative 'user_manager/manager_adapters/local'
        UserManager::ManagerAdapters::Local
      else
        if current_host.darwin?
          require_relative 'user_manager/manager_adapters/open_directory'
          UserManager::ManagerAdapters::OpenDirectory
        else
          require_relative 'user_manager/manager_adapters/unix'
          UserManager::ManagerAdapters::Unix
        end
      end

      @adapter.host_name = @host_name

      @adapter
    end
  end
end
