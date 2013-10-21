class Rosh
  class FileSystem
    module Adapters
      module RemoteStatMethods
        def <=>(other_file)
          other_object = FileSystem.create(other_file)

          mtime <=> other_object.mtime
        end

        def blksize
          RemoteStat.stat(@path, @host_name).blksize
        end

        def blockdev?
          RemoteStat.blockdev?(@path, @host_name)
        end

        def blocks
          RemoteStat.stat(@path, @host_name).blocks
        end

        def chardev?
          RemoteStat.chardev?(@path, @host_name)
        end

        def dev
          RemoteStat.stat(@path, @host_name).dev
        end

        def dev_major
          RemoteStat.dev_major(@path, @host_name)
        end

        def dev_minor
          RemoteStat.dev_minor(@path, @host_name)
        end

        # @return [Boolean] +true+ if the object is a directory; +false+ if not.
        def directory?
          RemoteStat.directory?(@path, @host_name)
        end

        def executable?
          RemoteStat.executable?(@path, @host_name)
        end

=begin
          def executable_real?

          end
=end

        # @return [Boolean] +true+ if the object is a file; +false+ if not.
        def file?
          RemoteStat.file?(@path, @host_name)
        end

        def gid
          RemoteStat.stat(@path, @host_name).gid
        end

        def grpowned?
          RemoteStat.grpowned?(@path, @host_name)
        end

        def ino
          RemoteStat.stat(@path, @host_name).ino
        end

        def mode
          RemoteStat.stat(@path, @host_name).mode
        end

        def nlink
          RemoteStat.stat(@path, @host_name).nlink
        end

        def owned?
          RemoteStat.owned?(@path, @host_name)
        end

        def pipe?
          RemoteStat.pipe?(@path, @host_name)
        end

        def rdev
          RemoteStat.stat(@path, @host_name).rdev
        end

        def rdev_major
          RemoteStat.dev_major(@path, @host_name)
        end

        def rdev_minor
          RemoteStat.dev_minor(@path, @host_name)
        end

        def readable?
          RemoteStat.readable?(@path, @host_name)
        end

=begin
          def readable_real?

          end
=end

        def setgid?
          RemoteStat.setgid?(@path, @host_name)
        end

        def setuid?
          RemoteStat.setuid?(@path, @host_name)
        end

        def size
          RemoteStat.stat(@path, @host_name).size
        end

        def socket?
          RemoteStat.socket?(@path, @host_name)
        end

        def sticky?
          RemoteStat.sticky?(@path, @host_name)
        end

        def symlink?
          RemoteStat.symlink?(@path, @host_name)
        end

        def uid
          RemoteStat.stat(@path, @host_name).uid
        end

        def world_readable?
          cmd = if current_host.darwin?
            "stat -f '%Sp' #{@path} | grep 'r\\S\\S$'"
          else
            "stat -c '%A' #{@path} | grep 'r\\S\\S$'"
          end

          current_shell.exec(cmd)

          current_shell.last_exit_status.zero?
        end

        def world_writable?
          cmd = if current_host.darwin?
            "stat -f '%Sp' #{@path} | grep 'w\\S$'"
          else
            "stat -c '%A' #{@path} | grep 'w\\S$'"
          end

          current_shell.exec(cmd)

          current_shell.last_exit_status.zero?
        end

        def writable?
          RemoteStat.writable?(@path, @host_name)
        end

=begin
          def writable_real?
          end
=end

        def zero?
          RemoteStat.zero?(@path, @host_name)
        end
      end
    end
  end
end
