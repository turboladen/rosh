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
        def self.included(base)
          base.extend ClassMethods
          base.extend RemoteStatMethods
        end

        module ClassMethods
          def path=(path)
            @path = path
          end

          def host_name=(host_name)
            @host_name = host_name
          end

          # @todo Do something with the block.
          # @return [Boolean]
          def create(&block)
            current_shell.exec "touch #{@path}"

            current_shell.last_exit_status.zero?
          end

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

          # @param [String,Integer] mode_int
          # @return [Boolean]
          def chmod(mode_int)
            current_shell.exec("chmod #{mode_int} #{@path}")

            current_shell.last_exit_status.zero?
          end

          # @param [String,Integer] uid
          # @param [String,Integer] gid
          # @return [Boolean]
          def chown(uid, gid=nil)
            cmd = "chown #{uid}"
            cmd << ":#{gid}" if gid
            cmd << " #{@path}"

            current_shell.exec cmd

            current_shell.last_exit_status.zero?
          end

          # @return [Time]
          def ctime
            RemoteStat.stat(@path, @host_name).ctime
          end

          # @return [Boolean]
          def delete
            current_shell.exec "rm #{@path}"

            current_shell.last_exit_status.zero?
          end

          # @return [String]
          def dirname
            ::File.dirname(@path)
          end

          # @return [Boolean] +true+ if the object exists on the file system;
          #   +false+ if not.
          def exists?
            cmd = "[ -e #{@path} ]"
            current_shell.exec(cmd)

            current_shell.last_exit_status.zero?
          end

          # @param [String] dir_string
          # @return [String]
          def expand_path(dir_string=nil)
            if current_host.darwin?
              warn 'Not implemented'
            else
              cmd = "readlink -f #{@path}"
              current_shell.exec(cmd).strip
            end
          end

          # @return [String]
          def extname
            ::File.extname(basename)
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

            output_string = current_shell.exec(cmd).strip.downcase

            output_string.gsub(/ /, '_').to_sym
          end

          # @param [String] new_path
          # @return [Boolean]
          def link(new_path)
            current_shell.exec "ln #{@path} #{new_path}"

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
            current_shell.exec("readlink #{@path}").strip
          end

          # @todo Use +dir_path+
          def realdirpath(dir_path=nil)
            current_shell.exec("readlink -f #{dirname}").strip
          end

          def realpath
            current_shell.exec("readlink -f #{@path}").strip
          end

          # @param [String] new_name
          # @return [Boolean]
          def rename(new_name)
            current_shell.exec("mv #{@path} #{new_name}")

            current_shell.last_exit_status.zero?
          end

          def split
            ::File.split(@path)
          end

          def to_path
            @path
          end

          def stat
            RemoteStat.stat(@path, @host_name)
          end

          # @param [String] new_name
          # @return [Boolean]
          def symlink(new_name)
            current_shell.exec("ln -s #{@path} #{new_name}")

            current_shell.last_exit_status.zero?
          end

          # @param [Integer] len
          # @return [Boolean]
          def truncate(len)
            current_shell.exec("head --bytes=#{len} --silent #{@path} > #{@path}")

            current_shell.last_exit_status.zero?
          end

          def utime(access_time, modification_time)
            atime_cmd = "touch -a --no-create --date=#{access_time}"
            mtime_cmd = "touch -m --no-create --date=#{modification_time}"

            current_shell.exec(atime_cmd)
            atime_ok = current_shell.last_exit_status.zero?

            current_shell.exec(mtime_cmd)
            mtime_ok = current_shell.last_exit_status.zero?

            (atime_ok && mtime_ok) ? 1 : 0
          end
        end
      end
    end
  end
end
