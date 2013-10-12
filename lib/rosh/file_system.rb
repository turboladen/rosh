require 'observer'
require_relative 'kernel_refinements'
require_relative 'file_system/file_system_controller'
require_relative 'file_system/file'
require_relative 'file_system/directory'
require_relative 'observable'


class Rosh
  class FileSystem
    include Rosh::Observable

    def self.create(path, host_name)
      object = new(host_name)

      if object.file?(path)
        object.file(path)
      elsif object.directory?(path)
        object.directory(path)
      else
        raise "Don't know what to do with #{path}"
      end
    end

    def initialize(host_name)
      @host_name = host_name

      unless current_host.local?
        require_relative 'file_system/remote_stat'
      end
    end

    def [](path)
      result = if path.is_a? Hash
        if path[:file]
          file(path[:file])
        elsif path[:dir]
          directory(path[:dir])
        elsif path[:directory]
          directory(path[:directory])
        elsif path[:link]
          link(path[:link])
        elsif path[:object]
          object(path[:object])
        else
          raise "Not sure what '#{path}' is."
        end
      else
        if file?(path)
          file(path)
        elsif directory?(path)
          directory(path)
        elsif link?(path)
          link(path)
        else
          object(path)
        end
      end

      result.add_observer(self)

      result
    end

    def chroot(new_root)
      controller.chroot(new_root, self)
    end

    def file(path)
      Rosh::FileSystem::File.new(path, @host_name)
    end

    def file?(path)
      controller.file?(path)
    end

    def directory?(path)
      controller.directory?(path)
    end

    def directory(path)
      Rosh::FileSystem::Directory.new(path, @host_name)
    end

    def link(path)
      Rosh::FileSystem::Link.new(path, @host_name)
    end

    def link?(path)
      controller.link?(path)
    end

    def object(path)
      Rosh::FileSystem::Object.new(path, @host_name)
    end

    def home
      controller.home
    end

    def umask
      controller.umask
    end

    def umask=(new_umask)
      controller.umask(new_umask, self)
    end

    def working_directory
      controller.getwd
    end
    alias_method :getwd, :working_directory

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

    def controller
      @controller ||= FileSystemController.new(@host_name)
    end
  end
end
