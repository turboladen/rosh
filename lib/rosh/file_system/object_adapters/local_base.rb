require_relative 'local_stat_methods'


class Rosh
  class FileSystem
    module ObjectAdapters

      # Base class for local file system objects.  Simply, it provides for
      # delegating to built-in Ruby Dir and File methods.
      module LocalBase

        # @param [String] dir_string
        def absolute_path(dir_string=nil)
          path = ::File.absolute_path(@path, dir_string)

          private_result(path, 0)
        end

        def atime
          time = ::File.atime(@path)

          private_result(time, 0)
        end

        # Just like Ruby's File#basename, returns the base name of the object.
        #
        # @param [String] suffix Removes the file suffix, if given.
        # @return [String]
        def basename(suffix=nil)
          name = if suffix
            ::File.basename(@path, suffix)
          else
            ::File.basename(@path)
          end

          private_result(name, 0)
        end

        def blockdev?
          result = ::File.blockdev?(@path)

          private_result(result, 0)
        end

        def chardev?
          result = ::File.chardev?(@path)

          private_result(result, 0)
        end

        def chmod(mode_int)
          result = ::File.chmod(mode_int, @path)

          private_result(result, 0)
        end

        # Allows setting user/group owner using key/value pairs.  If no value is
        # given for user or group, nothing will be changed.
        #
        # @param [Fixnum] :uid UID of the user to make owner.
        # @param [Fixnum] :gid GID of the group to make owner.
        # @return [Boolean] +true+ if successful, +false+ if not.
        def chown(uid: uid, gid: nil)
          result = ::File.chown(uid, gid, @path)
          actual_result = !result.zero?
          exit_status = actual_result ? 0 : 1

          private_result(actual_result, exit_status)
        end

        def ctime
          time = ::File.ctime(@path)

          private_result(time, 0)
        end

        def delete
          begin
            result = ::File.delete(@path)
            actual_result = !result.zero?
            exit_status = actual_result ? 0 : 1

            private_result(actual_result, exit_status)
          rescue Errno::ENOENT
            private_result(false, 1)
          end
        end

        def directory?
          result = ::File.directory?(@path)

          private_result(result, 0)
        end

        def dirname
          result = ::File.dirname(@path)

          private_result(result, 0)
        end

        def exists?
          result = ::File.exists? @path
          puts "result: #{result}"

          private_result(result, 0)
        end

        def expand_path(dir_string=nil)
          path = ::File.expand_path(@path, dir_string)

          private_result(path, 0)
        end

        def extname
          ext = ::File.extname(@path)

          private_result(ext, 0)
        end

        def file?
          result = ::File.file?(@path)

          private_result(result, 0)
        end

        def fnmatch(pattern, *flags)
          result = ::File.fnmatch(pattern, @path, *flags)

          private_result(result, 0)
        end
        alias_method :fnmatch?, :fnmatch

        # @todo Implement.
        def flock
          # Implement
        end

        def ftype
          type = ::File.ftype(path)

          private_result(type, 0)
        end

        def link(new_path)
          result = ::File.link(@path, new_path)
          actual_result = result.zero?
          exit_status = actual_result ? 0 : 1

          private_result(actual_result, exit_status)
        end

        def mtime
          time = ::File.mtime(@path)

          private_result(time, 0)
        end

=begin
        def open(mode, *options, &block)
          File.open(@path, options, block)
        end
=end

        def path
          p = ::File.path(@path)

          private_result(p, 0)
        end

        def readlink
          result = ::File.readlink(@path)

          private_result(result, 0)
        end

        def realdirpath(dir_path=nil)
          p = ::File.realdirpath(@path, dir_path)

          private_result(p, 0)
        end

        def realpath(dir_path=nil)
          path = ::File.realpath(@path, dir_path)

          private_result(path, 0)
        end

        def rename(new_name)
          result = ::File.rename(@path, new_name)
          actual_result = result.zero?
          exit_status = actual_result ? 0 : 1

          private_result(actual_result, exit_status)
        end

        def split
          result = ::File.split(@path)

          private_result(result, 0)
        end

        def stat
          s = ::File.stat(@path)

          private_result(s, 0)
        end

        def symlink(new_name)
          result = ::File.symlink(@path, new_name)
          actual_result = result.zero?
          exit_status = actual_result ? 0 : 1

          private_result(actual_result, exit_status)
        end

        def symlink?
          result = ::File.symlink?(@path)

          private_result(result, 0)
        end

        def truncate(len)
          result = ::File.truncate(@path, len)
          actual_result = result.zero?
          exit_status = actual_result ? 0 : 1

          private_result(actual_result, exit_status)
        end

        def unlink
          result = ::File.unlink(@path)
          actual_result = !result.zero?
          exit_status = actual_result ? 0 : 1

          private_result(actual_result, exit_status)
        end

        def utime(access_time, modification_time)
          time = ::File.utime(access_time, modification_time, @path)

          private_result(time, 0)
        end
      end
    end
  end
end
