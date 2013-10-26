require_relative 'base'


class Rosh
  class FileSystem
    module Adapters
      class RemoteFileSystem
        include Base

        class << self
          def blockdev?(path)
            RemoteStat.blockdev?(path, @host_name)
          end

          def chardev?(path)
            RemoteStat.chardev?(path, @host_name)
          end

          def chroot(new_root)
            current_shell.exec "chroot #{new_root}"
          end

          def directory?(path)
            RemoteStat.directory?(path, @host_name)
          end

          def file?(path)
            RemoteStat.file?(path, @host_name)
          end

          def getwd
            current_shell.exec('pwd').strip
          end

          def home
            current_shell.exec('echo ~').strip
          end

          def symlink?(path)
            RemoteStat.symlink?(path, @host_name)
          end

          def umask(new_umask=nil)
            if new_umask
              current_shell.exec("umask #{new_umask}").strip
            else
              current_shell.exec('umask').strip
            end
          end
        end
      end
    end
  end
end
