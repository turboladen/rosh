require 'etc'
require_relative 'local_stat_methods'


class Rosh
  class FileSystem
    module ObjectAdapters

      # Base class for local file system objects.  Simply, it provides for
      # delegating to built-in Ruby Dir and File methods.
      module LocalBase

        # @param [String] dir_string
        def absolute_path(dir_string=nil)
          ::File.absolute_path(@path, dir_string)
        end

        def atime
          ::File.atime(@path)
        end

        # Just like Ruby's File#basename, returns the base name of the object.
        #
        # @param [String] suffix Removes the file suffix, if given.
        # @return [String]
        def basename(suffix=nil)
          if suffix
            ::File.basename(@path, suffix)
          else
            ::File.basename(@path)
          end
        end

        def blockdev?
          ::File.blockdev?(@path)
        end

        def chardev?
          ::File.chardev?(@path)
        end

        def chmod(mode_int)
          ::File.chmod(mode_int, @path)
        end

        # Allows setting user/group owner using key/value pairs.  If no value is
        # given for user or group, nothing will be changed.
        #
        # @param [Fixnum] :uid UID of the user to make owner.
        # @param [Fixnum] :gid GID of the group to make owner.
        # @return [Boolean] +true+ if successful, +false+ if not.
        def chown(uid: uid, gid: nil)
          result = ::File.chown(uid, gid, @path)

          !result.zero?
        end

        def ctime
          ::File.ctime(@path)
        end

        def delete
          begin
            result = ::File.delete(@path)

            !result.zero?
          rescue Errno::ENOENT
            false
          end
        end

        def directory?
          ::File.directory?(@path)
        end

        def dirname
          ::File.dirname(@path)
        end

        def exists?
          ::File.exists? @path
        end

        def expand_path(dir_string=nil)
          ::File.expand_path(@path, dir_string)
        end

        def extname
          ::File.extname(@path)
        end

        def file?
          ::File.file?(@path)
        end

        def fnmatch(pattern, *flags)
          ::File.fnmatch(pattern, @path, *flags)
        end
        alias_method :fnmatch?, :fnmatch

        # @todo Implement.
        def flock
          # Implement
        end

        def ftype
          ::File.ftype(path)
        end

        def link(new_path)
          result = ::File.link(@path, new_path)

          result.zero?
        end

        def mtime
          ::File.mtime(@path)
        end

=begin
        def open(mode, *options, &block)
          File.open(@path, options, block)
        end
=end

        def path
          ::File.path(@path)
        end

        def readlink
          ::File.readlink(@path)
        end

        def realdirpath(dir_path=nil)
          ::File.realdirpath(@path, dir_path)
        end

        def realpath(dir_path=nil)
          ::File.realpath(@path, dir_path)
        end

        def rename(new_name)
          result = ::File.rename(@path, new_name)

          result.zero?
        end

        def split
          ::File.split(@path)
        end

        def stat
          ::File.stat(@path)
        end

        def symlink(new_name)
          result = ::File.symlink(@path, new_name)

          result.zero?
        end

        def symlink?
          ::File.symlink?(@path)
        end

        def truncate(len)
          result = ::File.truncate(@path, len)

          result.zero?
        end

        def unlink
          result = ::File.unlink(@path)

          !result.zero?
        end

        def utime(access_time, modification_time)
          ::File.utime(access_time, modification_time, @path)
        end
      end
    end
  end
end
