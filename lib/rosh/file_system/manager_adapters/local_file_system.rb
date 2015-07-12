class Rosh
  class FileSystem
    module ManagerAdapters
      # Methods that mimic Ruby's File API.
      module LocalFileSystem
        def blockdev?(path)
          return true if path.is_a? FileSystem::BlockDevice

          ::File.blockdev?(path)
        end

        def chardev?(path)
          return true if path.is_a? FileSystem::CharacterDevice

          ::File.chardev?(path)
        end

        def chroot(new_root)
          ::Dir.chroot(new_root)
        end

        def directory?(path)
          return true if path.is_a? FileSystem::Directory

          ::File.directory?(path)
        end

        def file?(path)
          return true if path.is_a? FileSystem::File

          ::File.file?(path)
        end

        def getwd
          path = ::Dir.getwd

          FileSystem::Directory.new(path, @host_name)
        end

        def home
          output = ::Dir.home

          FileSystem::Directory.new(output, @host_name)
        end

        def symlink?(path)
          return true if path.is_a? FileSystem::SymbolicLink

          ::File.symlink?(path)
        end

        def umask(new_umask = nil)
          if new_umask
            format('%o', ::File.umask(new_umask))
          else
            format('%o', ::File.umask)
          end
        end
      end
    end
  end
end
