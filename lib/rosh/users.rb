require_relative 'kernel_refinements'
require_relative 'observable'
require_relative 'users/object'
require_relative 'users/group'
require_relative 'users/user'


class Rosh
  class Users
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
      Rosh::Users::Group.new(name, @host_name)
    end

    def group?(name)
      adapter.group?(name)
    end

    def groups
      adapter.groups
    end

    def object(name)
      Rosh::Users::Object.new(name, @host_name)
    end

    def user(name)
      Rosh::Users::User.new(name, @host_name)
    end

    def user?(name)
      adapter.user?(name)
    end

    def users
      adapter.users
    end

    def update(obj, attribute, old_value, new_value, as_sudo)
      puts "I got updated!"
      puts  attribute
      puts  old_value
      puts  new_value
      puts  as_sudo

      self.changed
      self.notify_observers(obj,
        attribute,
        old_value,
        new_value,
        as_sudo
      )
    end

    private

    def adapter
      return @adapter if @adapter

      @adapter = if current_host.local?
        require_relative 'users/manager_adapters/local'
        Users::ManagerAdapters::Local
      else
        if current_host.darwin?
          require_relative 'users/manager_adapters/open_directory'
          Users::ManagerAdapters::OpenDirectory
        else
          require_relative 'users/manager_adapters/unix'
          Users::ManagerAdapters::Unix
        end
      end

      @adapter.host_name = @host_name

      @adapter
    end
  end
end
