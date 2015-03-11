require_relative 'local_stat_methods'


class Rosh
  class FileSystem
    module ObjectAdapters

      # Base class for local file system objects.  Simply, it provides for
      # delegating to built-in Ruby Dir and File methods.
      module LocalBase
        include LocalStatMethods

        # @param [String] dir_string
        def absolute_path(dir_string=nil)
          handle_errors_and_return_result { ::File.absolute_path(@path, dir_string) }
        end

        def atime
          handle_errors_and_return_result { ::File.atime(@path) }
        end

        # Just like Ruby's File#basename, returns the base name of the object.
        #
        # @param [String] suffix Removes the file suffix, if given.
        # @return [String]
        def basename(suffix=nil)
          handle_errors_and_return_result do
            if suffix
              ::File.basename(@path, suffix)
            else
              ::File.basename(@path)
            end
          end
        end

        def blockdev?
          handle_errors_and_return_result { ::File.blockdev?(@path) }
        end

        def chardev?
          handle_errors_and_return_result { ::File.chardev?(@path) }
        end

        def chmod(mode_int)
          handle_errors_and_return_result { ::File.chmod(mode_int, @path) }
        end

        # Allows setting user/group owner using key/value pairs.  If no value is
        # given for user or group, nothing will be changed.
        #
        # @param [Fixnum] uid UID of the user to make owner.
        # @param [Fixnum] gid GID of the group to make owner.
        # @return [Boolean] +true+ if successful, +false+ if not.
        def chown(uid, gid = nil)
          handle_errors_and_return_result do
            result = ::File.chown(uid, gid, @path)
            actual_result = !result.zero?
            exit_status = actual_result ? 0 : 1

            [actual_result, exit_status]
          end
        end

        def ctime
          handle_errors_and_return_result { ::File.ctime(@path) }
        end

        def delete
          handle_errors_and_return_result do
            result = ::File.delete(@path)
            actual_result = !result.zero?
            exit_status = actual_result ? 0 : 1

            [actual_result, exit_status]
          end
        end

        def directory?
          handle_errors_and_return_result { ::File.directory?(@path) }
        end

        def dirname
          handle_errors_and_return_result { ::File.dirname(@path) }
        end

        def exists?
          handle_errors_and_return_result { ::File.exists? @path }
        end

        def expand_path(dir_string=nil)
          handle_errors_and_return_result { ::File.expand_path(@path, dir_string) }
        end

        def extname
          handle_errors_and_return_result { ::File.extname(@path) }
        end

        def file?
          handle_errors_and_return_result { ::File.file?(@path) }
        end

        def fnmatch(pattern, *flags)
          handle_errors_and_return_result { :File.fnmatch(pattern, @path, *flags) }
        end
        alias_method :fnmatch?, :fnmatch

        # @todo Implement.
        def flock
          # Implement
        end

        def ftype
          handle_errors_and_return_result { ::File.ftype(@path) }
        end

        # @return [Rosh::FileSystem::*]
        def link(new_path)
          handle_errors_and_return_result do
            result = ::File.link(@path, new_path)
            actual_result = result.zero?
            exit_status = actual_result ? 0 : 1
            fso = current_host.fs[new_path]

            [fso, exit_status]
          end
        end

        def mtime
          handle_errors_and_return_result { ::File.mtime(@path) }
        end

=begin
        def open(mode, *options, &block)
          File.open(@path, options, block)
        end
=end

        def path
          handle_errors_and_return_result { ::File.path(@path) }
        end

        def readlink
          handle_errors_and_return_result { ::File.readlink(@path) }
        end

        def realdirpath(dir_path=nil)
          handle_errors_and_return_result { ::File.realdirpath(@path, dir_path) }
        end

        def realpath(dir_path=nil)
          handle_errors_and_return_result { ::File.realpath(@path, dir_path) }
        end

        def rename(new_name)
          handle_errors_and_return_result do
            result = ::File.rename(@path, new_name)
            actual_result = result.zero?
            exit_status = actual_result ? 0 : 1

            [actual_result, exit_status]
        end
      end

        def split
          handle_errors_and_return_result { ::File.split(@path) }
        end

        def stat
          handle_errors_and_return_result { ::File.stat(@path) }
        end

        def symlink(new_name)
          handle_errors_and_return_result do
            result = ::File.symlink(@path, new_name)
            actual_result = result.zero?
            exit_status = actual_result ? 0 : 1

            [actual_result, exit_status]
          end
        end

        def symlink?
          handle_errors_and_return_result { ::File.symlink?(@path) }
        end

        def truncate(len)
          handle_errors_and_return_result do
            result = ::File.truncate(@path, len)
            actual_result = result.zero?
            exit_status = actual_result ? 0 : 1

            [actual_result, exit_status]
          end
        end

        def unlink
          handle_errors_and_return_result do
            result = ::File.unlink(@path)
            actual_result = !result.zero?
            exit_status = actual_result ? 0 : 1

            [actual_result, exit_status]
          end
        end

        def utime(access_time, modification_time)
          handle_errors_and_return_result { ::File.utime(access_time, modification_time, @path) }
        end

        private

        def handle_errors_and_return_result(&block)
          result, exit_status = block.call
          exit_status ||= result ? 0 : 1

          private_result(result, exit_status)
        rescue Errno::ENOENT
          ex = Rosh::ErrorENOENT.new @path
          private_result(ex, 1, ex.message)
        rescue Errno::EEXIST
          ex = Rosh::ErrorEEXIST.new @path
          private_result(ex, 2, ex.message)
        end
      end
    end
  end
end
