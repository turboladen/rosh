class Rosh
  class FileSystem
    module ObjectAdapters
      module RemoteStatMethods
        def <=>(other_file)
          other_object = FileSystem.create(other_file)
          result = mtime <=> other_object.mtime

          private_result(result, 0)
        end

        def blksize
          size = RemoteStat.stat(@path, @host_name).blksize

          private_result(size, 0, size.to_s)
        end

        def blockdev?
          process { RemoteStat.blockdev?(@path, @host_name) }
        end

        def blocks
          b = RemoteStat.stat(@path, @host_name).blocks

          private_result(size, 0, b.to_s)
        end

        def chardev?
          process { RemoteStat.chardev?(@path, @host_name) }
        end

        def dev
          process { RemoteStat.stat(@path, @host_name).dev }
        end

        def dev_major
          d = RemoteStat.dev_major(@path, @host_name)

          private_result(d, 0, d.to_s)
        end

        def dev_minor
          d = RemoteStat.dev_minor(@path, @host_name)

          private_result(d, 0, d.to_s)
        end

        # @return [Boolean] +true+ if the object is a directory; +false+ if not.
        def directory?
          process { RemoteStat.directory?(@path, @host_name) }
        end

        def executable?
          process { RemoteStat.executable?(@path, @host_name) }
        end

        # TODO: Is this right?
        def executable_real?
          process { RemoteStat.executable_real?(@path, @host_name) }
        end

        # @return [Boolean] +true+ if the object is a file; +false+ if not.
        def file?
          process { RemoteStat.file?(@path, @host_name) }
        end

        def gid
          g = RemoteStat.stat(@path, @host_name).gid

          private_result(g, 0, g.to_s)
        end

        def grpowned?
          process { RemoteStat.grpowned?(@path, @host_name) }
        end

        def ino
          i = RemoteStat.stat(@path, @host_name).ino

          private_result(i, 0, i.to_s)
        end

        def mode
          process { RemoteStat.stat(@path, @host_name).mode }
        end

        def nlink
          process { RemoteStat.stat(@path, @host_name).nlink }
        end

        def owned?
          process { RemoteStat.owned?(@path, @host_name) }
        end

        def pipe?
          process { RemoteStat.pipe?(@path, @host_name) }
        end

        def rdev
          process { RemoteStat.stat(@path, @host_name).rdev }
        end

        def rdev_major
          process { RemoteStat.dev_major(@path, @host_name) }
        end

        def rdev_minor
          process { RemoteStat.dev_minor(@path, @host_name) }
        end

        def readable?
          process { RemoteStat.readable?(@path, @host_name) }
        end

        # TODO: Is this right?
        def readable_real?
          process { RemoteStat.readable_real?(@path, @host_name) }
        end

        def setgid?
          process { RemoteStat.setgid?(@path, @host_name) }
        end

        def setuid?
          process { RemoteStat.setuid?(@path, @host_name) }
        end

        def size
          s = RemoteStat.stat(@path, @host_name).size

          private_result(s, 0, s.to_s)
        end

        def socket?
          process { RemoteStat.socket?(@path, @host_name) }
        end

        def sticky?
          process { RemoteStat.sticky?(@path, @host_name) }
        end

        def symlink?
          process { RemoteStat.symlink?(@path, @host_name) }
        end

        def uid
          u = RemoteStat.stat(@path, @host_name).uid

          private_result(u, 0, u.to_s)
        end

        def world_readable?
          cmd = if host.darwin?
            "stat -f '%Sp' #{@path} | grep 'r\\S\\S$'"
          else
            "stat -c '%A' #{@path} | grep 'r\\S\\S$'"
          end

          host.shell.exec_internal(cmd)
          result = host.shell.last_exit_status.zero?
          exit_status = result ? 0 : 1

          private_result(result, exit_status)
        end

        def world_writable?
          cmd = if host.darwin?
            "stat -f '%Sp' #{@path} | grep 'w\\S$'"
          else
            "stat -c '%A' #{@path} | grep 'w\\S$'"
          end

          host.shell.exec_internal(cmd)
          result = host.shell.last_exit_status.zero?
          exit_status = result ? 0 : 1

          private_result(result, exit_status)
        end

        def writable?
          process { RemoteStat.writable?(@path, @host_name) }
        end

        # TODO: Is this right?
        def writable_real?
          process { RemoteStat.writable_real?(@path, @host_name) }
        end

        def zero?
          process { RemoteStat.zero?(@path, @host_name) }
        end

        private

        def process
          result = yield

          private_result(result, 0)
        end
      end
    end
  end
end
