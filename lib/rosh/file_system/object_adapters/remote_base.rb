require_relative '../remote_stat'
require_relative 'remote_stat_methods'


class Rosh
  class FileSystem
    module ObjectAdapters

      # This is a generic base class for representing file system objects: files,
      # directories, and links.  It implements what's pretty close to Ruby's
      # +File+ class.
      #
      # When serializing (i.e. dumping to YAML), it maintains only the path to the
      # object.
      module RemoteBase
        def absolute_path(dir_string=nil)
          warn 'Not implemented!'
        end

        # @return [Time]
        def atime
          time = RemoteStat.stat(@path, @host_name).atime

          private_result(time, 0)
        end

        # @param [String] suffix
        # @return [String]
        def basename(suffix=nil)
          cmd = "basename #{@path}"
          cmd << " #{suffix}" if suffix

          private_result(current_shell.exec_internal(cmd).strip, 0)
        end

        def blockdev?
          result = RemoteStat.blockdev?(@path, @host_name)

          private_result(result, 0)
        end

        def chardev?
          result = RemoteStat.chardev?(@path, @host_name)

          private_result(result, 0)
        end

        # @param [String,Integer] mode_int
        # @return [Boolean]
        def chmod(mode_int)
          current_shell.exec_internal("chmod #{mode_int} #{@path}")
          result = current_shell.last_exit_status.zero?

          private_result(result, 0)
        end

        # @param [String,Integer] uid
        # @param [String,Integer] gid
        # @return [Boolean]
        def chown(uid, gid=nil)
          cmd = "chown #{uid}"
          cmd << ":#{gid}" if gid
          cmd << " #{@path}"

          current_shell.exec_internal cmd
          result = current_shell.last_exit_status.zero?
          exit_status = result ? 0 : 1

          private_result(result, exit_status)
        end

        # @return [Time]
        def ctime
          time = RemoteStat.stat(@path, @host_name).ctime

          private_result(time, 0)
        end

        # @return [Boolean]
        def delete
          current_shell.exec_internal "rm #{@path}"
          result = current_shell.last_exit_status.zero?
          exit_status = result ? 0 : 1

          private_result(result, exit_status)
        end

        def directory?
          result = RemoteStat.directory?(@path, @host_name)

          private_result(result, 0)
        end

        # @return [String]
        def dirname
          name = ::File.dirname(@path)

          private_result(name, 0)
        end

        # @return [Boolean] +true+ if the object exists on the file system;
        #   +false+ if not.
        def exists?
          cmd = "test -e #{@path}"
          current_shell.exec_internal(cmd)
          result = current_shell.last_exit_status.zero?
          exit_status = result ? 0 : 1

          private_result(result, exit_status)
        end

        # @param [String] dir_string
        # @return [String]
        def expand_path(dir_string=nil)
          result = if current_host.darwin?
            warn 'Not implemented'
          else
            cmd = "readlink -f #{@path}"
            current_shell.exec_internal(cmd).strip
          end

          private_result(result, 0)
        end

        # @return [String]
        def extname
          ext = ::File.extname(basename)

          private_result(ext, 0)
        end

        def file?
          result = RemoteStat.file?(@path, @host_name)

          private_result(result, 0)
        end

        # @todo Implement.
        def fnmatch(pattern, *flags)
          warn 'Not implemented'
        end

        # @return [Symbol]
        def ftype
          cmd = if current_host.darwin?
            "stat -n -f '%HT' #{@path}"
          else
            "stat -c '%F' #{@path}"
          end

          output_string = current_shell.exec_internal(cmd).strip.downcase
          result = output_string.gsub(/ /, '_').to_sym

          private_result(result, 0)
        end

        # @param [String] new_path
        # @return [Boolean]
        def link(new_path)
          current_shell.exec_internal "ln #{@path} #{new_path}"
          result = current_shell.last_exit_status.zero?
          exit_status = result ? 0 : 1

          private_result(result, exit_status)
        end

        # @return [Time]
        def mtime
          time = RemoteStat.stat(@path, @host_name).mtime

          private_result(time, 0)
        end

        def path
          private_result(@path, 0)
        end

        # @return [String]
        def readlink
          result = current_shell.exec_internal("readlink #{@path}").strip

          private_result(result, 0)
        end

        # @todo Use +dir_path+
        def realdirpath(dir_path=nil)
          result = current_shell.exec_internal("readlink -f #{dirname}").strip

          private_result(result, 0)
        end

        def realpath
          result = current_shell.exec_internal("readlink -f #{@path}").strip

          private_result(result, 0)
        end

        # @param [String] new_name
        # @return [Boolean]
        def rename(new_name)
          current_shell.exec_internal("mv #{@path} #{new_name}")
          result = current_shell.last_exit_status.zero?
          exit_status = result ? 0 : 1

          private_result(result, exit_status)
        end

        def split
          result = ::File.split(@path)

          private_result(result, 0)
        end

        def stat
          s = RemoteStat.stat(@path, @host_name)

          private_result(s, 0)
        end

        # @param [String] new_name
        # @return [Boolean]
        def symlink(new_name)
          current_shell.exec_internal("ln -s #{@path} #{new_name}")
          result = current_shell.last_exit_status.zero?

          private_result(result, 0)
        end

        def symlink?
          result = RemoteStat.symlink?(@path, @host_name)

          private_result(result, 0)
        end

        # @param [Integer] len
        # @return [Boolean]
        def truncate(len)
          current_shell.exec_internal("head --bytes=#{len} --silent #{@path} > #{@path}")
          result = current_shell.last_exit_status.zero?

          private_result(result, 0)
        end

        def utime(access_time, modification_time)
          atime_cmd = "touch -a --no-create --date=#{access_time}"
          mtime_cmd = "touch -m --no-create --date=#{modification_time}"

          current_shell.exec_internal(atime_cmd)
          atime_ok = current_shell.last_exit_status.zero?

          current_shell.exec_internal(mtime_cmd)
          mtime_ok = current_shell.last_exit_status.zero?

          result = atime_ok && mtime_ok
          exit_status = result ? 0 : 1

          private_result(result, exit_status)
        end
      end
    end
  end
end
