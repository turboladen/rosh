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
          RemoteStat.stat(@path, @host_name).atime
        end

        # @param [String] suffix
        # @return [String]
        def basename(suffix=nil)
          cmd = "basename #{@path}"
          cmd << " #{suffix}" if suffix

          current_shell.exec(cmd).strip
        end

        def blockdev?
          RemoteStat.blockdev?(@path, @host_name)
        end

        def chardev?
          RemoteStat.chardev?(@path, @host_name)
        end

        # @param [String,Integer] mode_int
        # @return [Boolean]
        def chmod(mode_int)
          current_shell.exec_internal("chmod #{mode_int} #{@path}")

          current_shell.last_exit_status.zero?
        end

        # @param [String,Integer] uid
        # @param [String,Integer] gid
        # @return [Boolean]
        def chown(uid, gid=nil)
          cmd = "chown #{uid}"
          cmd << ":#{gid}" if gid
          cmd << " #{@path}"

          current_shell.exec_internal cmd

          current_shell.last_exit_status.zero?
        end

        # @return [Time]
        def ctime
          RemoteStat.stat(@path, @host_name).ctime
        end

        # @return [Boolean]
        def delete
          current_shell.exec_internal "rm #{@path}"

          current_shell.last_exit_status.zero?
        end

        def directory?
          RemoteStat.directory?(@path, @host_name)
        end

        # @return [String]
        def dirname
          ::File.dirname(@path)
        end

        # @return [Boolean] +true+ if the object exists on the file system;
        #   +false+ if not.
        def exists?
          cmd = "test -e #{@path}"
          current_shell.exec_internal(cmd)

          current_shell.last_exit_status.zero?
        end

        # @param [String] dir_string
        # @return [String]
        def expand_path(dir_string=nil)
          if current_host.darwin?
            warn 'Not implemented'
          else
            cmd = "readlink -f #{@path}"
            current_shell.exec_internal(cmd).strip
          end
        end

        # @return [String]
        def extname
          ::File.extname(basename)
        end

        def file?
          RemoteStat.file?(@path, @host_name)
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

          output_string.gsub(/ /, '_').to_sym
        end

        # @param [String] new_path
        # @return [Boolean]
        def link(new_path)
          current_shell.exec_internal "ln #{@path} #{new_path}"

          current_shell.last_exit_status.zero?
        end

        # @return [Time]
        def mtime
          RemoteStat.stat(@path, @host_name).mtime
        end

        def path
          @path
        end

        # @return [String]
        def readlink
          result = current_shell.exec_internal("readlink #{@path}").strip
        end

        # @todo Use +dir_path+
        def realdirpath(dir_path=nil)
          result = current_shell.exec_internal("readlink -f #{dirname}").strip
        end

        def realpath
          result = current_shell.exec_internal("readlink -f #{@path}").strip
        end

        # @param [String] new_name
        # @return [Boolean]
        def rename(new_name)
          current_shell.exec_internal("mv #{@path} #{new_name}")

          current_shell.last_exit_status.zero?
        end

        def split
          ::File.split(@path)
        end

        def stat
          RemoteStat.stat(@path, @host_name)
        end

        # @param [String] new_name
        # @return [Boolean]
        def symlink(new_name)
          current_shell.exec_internal("ln -s #{@path} #{new_name}")

          current_shell.last_exit_status.zero?
        end

        def symlink?
          RemoteStat.symlink?(@path, @host_name)
        end

        # @param [Integer] len
        # @return [Boolean]
        def truncate(len)
          current_shell.exec_internal("head --bytes=#{len} --silent #{@path} > #{@path}")

          current_shell.last_exit_status.zero?
        end

        def utime(access_time, modification_time)
          atime_cmd = "touch -a --no-create --date=#{access_time}"
          mtime_cmd = "touch -m --no-create --date=#{modification_time}"

          current_shell.exec_internal(atime_cmd)
          atime_ok = current_shell.last_exit_status.zero?

          current_shell.exec_internal(mtime_cmd)
          mtime_ok = current_shell.last_exit_status.zero?

          (atime_ok && mtime_ok) ? 1 : 0
        end
      end
    end
  end
end
