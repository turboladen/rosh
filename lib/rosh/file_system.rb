require 'observer'
require_relative 'kernel_refinements'
require_relative 'file_system/file'
require_relative 'file_system/directory'

class Rosh
  class FileSystem
    include Observable

    def self.create(path, host_name)
      object = new(host_name)

      if object.file?(path)
        Rosh::FileSystem::File.new(path, host_name)
      elsif object.directory?(path)
        Rosh::FileSystem::Directory.new(path, host_name)
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

    def umask
      if current_host.local?
        sprintf('%o', ::File.umask)
      else
        current_shell.exec 'umask'
      end
    end

    def umask=(new_umask)
      if current_host.local?
        sprintf('%o', ::File.umask(new_umask))
      else
        current_shell.exec "umask #{new_umask}"
      end
    end

    def chroot(new_root)
      if current_host.local?
        ::Dir.chroot(new_root)
      else
        current_shell.exec "chroot #{new_root}"
      end
    end

    def file?(path)
      if current_host.local?
        ::File.file?(path)
      else
        RemoteStat.file?(path, @host_name)
      end
    end

    def directory?(path)
      if current_host.local?
        ::File.directory?(path)
      else
        RemoteStat.directory?(path, @host_name)
      end
    end

    def home
      if current_host.local?
        ::Dir.home
      else
        current_shell.exec('echo ~').strip
      end
    end

    def working_directory
      if current_host.local?
        ::Dir.getwd
      else
        current_shell.exec('pwd').strip
      end
    end
    alias_method :getwd, :working_directory

    def file(path)
      Rosh::FileSystem::File.new(path, @host_name)
    end

    def directory(path)
      Rosh::FileSystem::Directory.new(path, @host_name)
    end
  end
end
