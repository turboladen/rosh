require_relative 'kernel_refinements'
require_relative 'changeable'
require_relative 'observer'
require_relative 'observable'

require_relative 'file_system/block_device'
require_relative 'file_system/character_device'
require_relative 'file_system/directory'
require_relative 'file_system/file'
require_relative 'file_system/object'
require_relative 'file_system/symbolic_link'
require_relative 'file_system/manager_adapter'


class Rosh
  class FileSystem
    include Rosh::Changeable
    include Rosh::Observer
    include Rosh::Observable

    def self.create(path, host_name)
      object = new(host_name)
      object.build(path)
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
        elsif path[:symbolic_link]
          symbolic_link(path[:symbolic_link])
        elsif path[:character_device]
          character_device(path[:character_device])
        elsif path[:block_device]
          block_device(path[:block_device])
        elsif path[:object]
          object(path[:object])
        else
          raise "Not sure what '#{path}' is."
        end
      else
        build(path)
      end

      result.add_observer(self)

      result
    end

    def block_device(path)
      Rosh::FileSystem::BlockDevice.new(path, @host_name)
    end

    def block_device?(path)
      return true if path.is_a? FileSystem::BlockDevice

      adapter.blockdev?(path)
    end

    def character_device(path)
      Rosh::FileSystem::CharacterDevice.new(path, @host_name)
    end

    def character_device?(path)
      return true if path.is_a? FileSystem::CharacterDevice

      adapter.chardev?(path)
    end

    def chroot(new_root)
      old_root = @root_directory

      change_if(old_root != new_root) do
        notify_about(self, :root_directory, from: old_root, to: new_root) do
          adapter.chroot(new_root)
        end
      end
    end

    def build(path)
      if file?(path)
        file(path)
      elsif directory?(path)
        directory(path)
      elsif symbolic_link?(path)
        symbolic_link(path)
      elsif character_device?(path)
        character_device(path)
      elsif block_device?(path)
        block_device(path)
      else
        object(path)
      end
    end

    def directory?(path)
      return true if path.is_a? FileSystem::Directory

      adapter.directory?(path)
    end

    def directory(path)
      Rosh::FileSystem::Directory.new(path, @host_name)
    end

    def file(path)
      Rosh::FileSystem::File.new(path, @host_name)
    end

    def file?(path)
      return true if path.is_a? FileSystem::File

      adapter.file?(path)
    end

    def home
      adapter.home
    end

    def object(path)
      Rosh::FileSystem::Object.new(path, @host_name)
    end

    def symbolic_link(path)
      Rosh::FileSystem::SymbolicLink.new(path, @host_name)
    end

    def symbolic_link?(path)
      return true if path.is_a? FileSystem::SymbolicLink

      adapter.symlink?(path)
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

    private

    def adapter
      return @adapter if @adapter

      type = if current_host.local?
        :local_file_system
      else
        :remote_file_system
      end

      @adapter = FileSystem::ManagerAdapter.new(type, @host_name)
    end
  end
end
