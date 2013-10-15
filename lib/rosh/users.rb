require_relative 'kernel_refinements'
require_relative 'observable'
require_relative 'users/user'


class Rosh
  class Users
    include Rosh::Observable

    def self.create(name, host_name)
      object = new(host_name)

      if object.open_directory?
        object.open_directory(name)
      else
        raise "Don't know what to do with #{name}"
      end
    end

    def initialize(host_name)
      @host_name = host_name
    end

    def [](name)
      result = if open_directory?
        open_directory name
      else
        object name
      end

      result.add_observer(self)

      result
    end

    def list
      adapter.list
    end

    def open_directory(name)
      Rosh::Users::User.new(name, :open_directory, @host_name)
    end

    def open_directory?
      adapter.open_directory?
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

      require_relative 'users/manager_adapters/open_directory'

      @adapter = Users::ManagerAdapters::OpenDirectory
      @adapter.host_name = @host_name

      @adapter
    end
  end
end
