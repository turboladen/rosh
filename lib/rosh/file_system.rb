require 'observer'
require_relative 'kernel_refinements'
require_relative 'file_system/file_system_controller'
require_relative 'file_system/file'
require_relative 'file_system/directory'

class Rosh
  class FileSystem
    include Observable

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
      if path.is_a? Hash
        if path[:file]
          file(path[:file])
        elsif path[:dir]
          directory(path[:dir])
        elsif path[:directory]
          directory(path[:directory])
        else
          raise "Not sure what '#{path}' is."
        end
      else
        if file?(path)
          file(path)
        elsif directory?(path)
          directory(path)
        else
          raise "Not sure what '#{path}' is."
        end
      end
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

    private

    def controller
      @controller ||= FileSystemController.new(@host_name)
    end
  end
end
