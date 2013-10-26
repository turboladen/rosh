require_relative 'base'


class Rosh
  class FileSystem
    module ManagerAdapters
      class LocalFileSystem
        include Base

        class << self
          def blockdev?(path)
            ::File.blockdev?(path)
          end

          def chardev?(path)
            ::File.chardev?(path)
          end

          def chroot(new_root)
            ::Dir.chroot(new_root)
          end

          def directory?(path)
            ::File.directory?(path)
          end

          def file?(path)
            ::File.file?(path)
          end

          def getwd
            ::Dir.getwd
          end

          def home
            ::Dir.home
          end

          def symlink?(path)
            ::File.symlink?(path)
          end

          def umask(new_umask=nil)
            if new_umask
              sprintf('%o', ::File.umask(new_umask))
            else
              sprintf('%o', ::File.umask)
            end
          end
        end
      end
    end
  end
end
