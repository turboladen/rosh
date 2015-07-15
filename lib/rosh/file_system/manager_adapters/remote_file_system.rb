require_relative '../file'
require_relative '../directory'
require_relative '../block_device'
require_relative '../character_device'
require_relative '../symbolic_link'

class Rosh
  class FileSystem
    module ManagerAdapters
      module RemoteFileSystem
        def blockdev?(path)
          return true if path.is_a? FileSystem::BlockDevice

          RemoteStat.blockdev?(path, @host_name)
        end

        def chardev?(path)
          return true if path.is_a? FileSystem::CharacterDevice

          RemoteStat.chardev?(path, @host_name)
        end

        def chroot(new_root)
          current_shell.exec_internal "chroot #{new_root}"
        end

        def directory?(path)
          return true if path.is_a? FileSystem::Directory

          RemoteStat.directory?(path, @host_name)
        end

        def file?(path)
          return true if path.is_a? FileSystem::File

          RemoteStat.file?(path, @host_name)
        end

        def getwd
          output = current_shell.exec_internal('pwd').strip

          FileSystem::Directory.new(output, @host_name)
        end

        def home
          output = current_shell.exec_internal('echo ~').strip

          FileSystem::Directory.new(output, @host_name)
        end

        def symlink?(path)
          return true if path.is_a? FileSystem::SymbolicLink

          RemoteStat.symlink?(path, @host_name)
        end

        def umask(new_umask = nil)
          if new_umask
            current_shell.exec_internal("umask #{new_umask}").strip
          else
            current_shell.exec_internal('umask').strip
          end
        end
      end
    end
  end
end
