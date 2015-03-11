require 'drama_queen/producer'
require 'drama_queen/consumer'
require 'simple_states'

require_relative 'kernel_refinements'
require_relative 'logger'
require_relative 'command'
require_relative 'file_system/block_device'
require_relative 'file_system/character_device'
require_relative 'file_system/directory'
require_relative 'file_system/file'
require_relative 'file_system/object'
require_relative 'file_system/symbolic_link'
require_relative 'file_system/manager_adapter'


class Rosh

  # Sub-module of the Rosh system, used for working with a local or remote file
  # system.  It behaves somewhat like an ORM for working with file system
  # objects.
  class FileSystem
    class UnknownObjectType < RuntimeError
      def initialize(resource_type)
        message = "Resource type '#{resource_type}' does not exist."
        super(message)
      end
    end

    include DramaQueen::Consumer
    include Rosh::Logger
    include Rosh::FileSystem::StateMachine

    # Create a new file system object at the given +path+.  This is really just
    # a proxy (Ruby) object that represents the actual file-system object.  The
    # actual file-system object may or may not exist on-disk; calling this
    # method simply creates the Ruby object--if you want to persist the object
    # to disk, you need to tell the object to persist.  See documentation for
    # each respective FS object type for more info on persisting those objects.
    #
    # @param path [String] Path to the file system object on the host given by
    #   +host_name+.
    # @todo What if the fs object doesn't exist?  What type is created?
    def self.create(path, host_name)
      @object ||= new(host_name)
      @object.build(path)
    end

    # This is a call-back for when one of the known file system objects
    # changes.
    def update(*args)
      puts "file system updated with args: #{args}"
    end

    # @param [String] host_name
    def initialize(host_name)
      @host_name = host_name
      @root_directory = '/'
      # Subscribe to all file system objects that send an :update event.
      self.subscribe('rosh.file_system.*', :update)

      unless Rosh.environment.current_host.local?
        require_relative 'file_system/remote_stat'
      end
    end

    # Creates a Rosh::FileSystem::* object based on the actual file system type
    # resource and adds itself as an observer of the newly created object.
    #
    # If given a String, it tries to figure out what the resource is
    # and returns the according Rosh object.  If it can't determine what type
    # it is, it returns a Rosh::FileSystem::Object.
    #
    # If given a key/value pair, it creates a Rosh object that maps to the key:
    #   * :file => Rosh::FileSystem::File
    #   * :dir => Rosh::FileSystem::Directory
    #   * :directory => Rosh::FileSystem::Directory
    #   * :symbolic_link => Rosh::FileSystem::SymbolicLink
    #   * :character_device => Rosh::FileSystem::CharacterDevice
    #   * :block_device => Rosh::FileSystem::BlockDevice
    #
    # @param [Hash,String] path File system path to the object to build.
    # @return [Rosh::FileSystem::*]
    # @raises [Rosh::FileSystem::UnknownObjectType] If given a key that does
    #   not map to an object type.
    def [](path)
      fs_object = if path.is_a? Hash
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
          raise UnknownObjectType, path.keys.first
        end
      else
        build(path)
      end

      # After creating the object, subscribe to its :update event.
      subscribe fs_object, :update

      fs_object
    end

    # @param [String] path File system path to the object to build.
    # @return [Rosh::FileSystem::*]
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

    # Create a proxy object to a block device at the given +path+.
    #
    # @param path [String]
    # @return [Rosh::FileSystem::BlockDevice]
    def block_device(path)
      Rosh::FileSystem::BlockDevice.new(path, @host_name)
    end

    # Checks if the file system object at +path+ is a block device.
    #
    # @param path [String]
    # @return [Boolean]
    def block_device?(path)
      return true if path.is_a? FileSystem::BlockDevice

      adapter.blockdev?(path)
    end

    # Create a proxy object to a character device at the given +path+.
    #
    # @param path [String]
    # @return [Rosh::FileSystem::CharacterDevice]
    def character_device(path)
      Rosh::FileSystem::CharacterDevice.new(path, @host_name)
    end

    # Checks if the file system object at +path+ is a character device.
    #
    # @param path [String]
    # @return [Boolean]
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

    # Create a proxy object to a directory at the given +path+.
    #
    # @param path [String]
    # @return [Rosh::FileSystem::Directory]
    def directory(path)
      Rosh::FileSystem::Directory.new(path, @host_name)
    end

    # Checks if the file system object at +path+ is a directory.
    #
    # @param path [String]
    # @return [Boolean]
    def directory?(path)
      return true if path.is_a? FileSystem::Directory

      adapter.directory?(path)
    end

    # Create a proxy object to a file at the given +path+.
    #
    # @param path [String]
    # @return [Rosh::FileSystem::File]
    def file(path)
      f = Rosh::FileSystem::File.new(path, @host_name)
      subscribe f, :update

      f
    end

    # Checks if the file system object at +path+ is a file.
    #
    # @param path [String]
    # @return [Boolean]
    def file?(path)
      return true if path.is_a? FileSystem::File

      adapter.file?(path)
    end

    # The current user's home directory.
    #
    # @return [Rosh::FileSystem::Directory]
    def home
      adapter.home
    end

    # Create a proxy object to a generic file system object at the given +path+.
    #
    # @param path [String]
    # @return [Rosh::FileSystem::Object]
    def object(path)
      Rosh::FileSystem::Object.new(path, @host_name)
    end

    # Checks if the file system object at +path+ is a generic file system
    # object.
    #
    # @param path [String]
    # @return [Boolean]
    def object?(path)
      return true if path.is_a? FileSystem::Object

      false
    end

    # Create a proxy object to a symbolic link at the given +path+.
    #
    # @param path [String]
    # @return [Rosh::FileSystem::SymbolicLink]
    def symbolic_link(path)
      Rosh::FileSystem::SymbolicLink.new(path, @host_name)
    end

    # Checks if the file system object at +path+ is a symbolic link.
    #
    # @param path [String]
    # @return [Boolean]
    def symbolic_link?(path)
      return true if path.is_a? FileSystem::SymbolicLink

      adapter.symlink?(path)
    end

    # Returns the umask for the current user.
    #
    # @param [String]
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

    # The current working directory.
    #
    # @return [Rosh::FileSystem::Directory]
    def working_directory
      adapter.getwd
    end
    alias_method :getwd, :working_directory

    private

    def adapter
      return @adapter if @adapter

      type = if Rosh.environment.current_host.local?
        :local_file_system
      else
        :remote_file_system
      end

      @adapter = FileSystem::ManagerAdapter.new(type, @host_name)
    end
  end
end
