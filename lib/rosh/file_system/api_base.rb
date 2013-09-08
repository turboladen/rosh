require 'observer'


class Rosh
  class FileSystem
    module APIBase
      include Observable

      # @param [String] dir_string
      def absolute_path(dir_string=nil)
        controller.absolute_path(dir_string)
      end

      def access_time
        controller.atime
      end
      alias_method :atime, :access_time

      # Just like Ruby's File#basename, returns the base name of the object.
      #
      # @param [String] suffix
      # @return [String]
      def base_name(suffix=nil)
        controller.basename(suffix)
      end
      alias_method :basename, :base_name

      def change_mode_to(new_mode)
        controller.chmod(new_mode, self)
      end
      alias_method :chmod, :change_mode_to

      def change_owner_to(uid: nil, gid: nil)
        controller.chown(self, uid: uid, gid: gid)
      end
      alias_method :owner=, :change_owner_to
      alias_method :chown, :change_owner_to

      def change_time
        controller.ctime
      end
      alias_method :ctime, :change_time

      def delete
        controller.delete(self)
      end
      alias_method :unlink, :delete

      def expand_path(dir_string=nil)
        controller.expand_path(dir_string)
      end

      def extension
        controller.extname
      end
      alias_method :extname, :extension

      def file_name_match(pattern, *flags)
        controller.fnmatch(pattern, *flags)
      end
      alias_method :fnmatch, :file_name_match
      alias_method :fnmatch?, :file_name_match

      def file_type
        controller.ftype
      end
      alias_method :ftype, :file_type

      def lchmod(mode_int)
        controller.lchmod(mode_int, self)
      end

      def lchown(uid: nil, gid: nil)
        controller.lchown(uid, gid, self)
      end

      def hard_link_to(new_path)
        controller.link(new_path, self)
      end
      alias_method :link, :hard_link_to

      def lstat
        controller.lstat
      end

      def modification_time
        controller.mtime
      end
      alias_method :mtime, :modification_time

      def path
        controller.path
      end

      def read_link
        controller.readlink
      end
      alias_method :readlink, :read_link

      def real_dir_path(dir_path=nil)
        controller.realdirpath(dir_path)
      end
      alias_method :realdirpath, :real_dir_path

      def real_path(dir_path=nil)
        controller.realpath(dir_path)
      end
      alias_method :realpath, :real_path

      def rename_to(new_name)
        controller.rename(new_name, self)
      end
      alias_method :rename, :rename_to

      def split
        controller.split
      end

      def stat
        controller.stat
      end

      def symbolic_link_to(new_path)
        controller.symlink(new_path, self)
      end
      alias_method :symlink, :symbolic_link_to

      def truncate(new_length)
        controller.truncate(new_length, self)
      end

      def file_times=(access_time, modification_time)
        controller.utime(access_time, modification_time, self)
      end
      alias_method :utime, :file_times=

      def lock(types)
        controller.flock(types)
      end
      alias_method :flock, :lock
    end
  end
end
