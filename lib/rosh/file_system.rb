require 'observer'
require_relative 'kernel_refinements'
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
      @root_directory = '/'

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
      old_root = @root_directory

      change_if(old_root != new_root) do
        notify_about(self, :root_directory, from: old_root, to: new_root) do
          adapter.chroot(new_root)
        end
      end
    end

    def file(path)
      Rosh::FileSystem::File.new(path, @host_name)
    end

    def file?(path)
      adapter.file?(path)
    end

    def directory?(path)
      adapter.directory?(path)
    end

    def directory(path)
      Rosh::FileSystem::Directory.new(path, @host_name)
    end

    def link(path)
      Rosh::FileSystem::Link.new(path, @host_name)
    end

    def link?(path)
      adapter.link?(path)
    end

    def object(path)
      Rosh::FileSystem::Object.new(path, @host_name)
    end

    def home
      adapter.home
    end

    def umask
      adapter.umask
    end

    def umask=(new_umask)
      old_umask = self.umask

      change_if(old_umask != new_umask) do
        notify_about(self, :umask, from: old_umask, to: new_umask) do
          adapter.umask(new_umask)
        end
      end
    end

    def working_directory
      adapter.getwd
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

    def adapter
      return @adapter if @adapter

      @adapter = if current_host.local?
        require_relative 'file_system/adapters/local_file_system'
        FileSystem::Adapters::LocalFileSystem
      else
        require_relative 'file_system/adapters/remote_file_system'
        FileSystem::Adapters::RemoteFileSystem
      end

      @adapter.host_name = @host_name

      @adapter
    end
  end
end
