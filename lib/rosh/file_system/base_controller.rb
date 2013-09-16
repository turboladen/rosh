require_relative '../string_refinements'


class Rosh
  class FileSystem
    # TODO: Add IO methods.
    module BaseController

      # @return [String] The path that was used to initialize the object.
      attr_reader :path

      # Returns the pathname used to create file as a String. Does not normalize
      # the name.
      #
      # @return [String]
      def to_path
        @path
      end

      # @param [String] dir_string
      def absolute_path(dir_string=nil)
        adapter.absolute_path(dir_string)
      end

      def atime
        adapter.atime
      end

      # Just like Ruby's File#basename, returns the base name of the object.
      #
      # @param [String] suffix
      # @return [String]
      def basename(suffix=nil)
        adapter.basename(suffix)
      end

      def chmod(mode_int, watched_object)
        old_mode = adapter.mode
        result = adapter.chmod(mode_int)

        if result == 1 && mode_int != old_mode.to_i
          watched_object.changed
          watched_object.notify_observers(watched_object,
            attribute: :mode,
            old: old_mode, new: mode_int, as_sudo: nil
          )
        end

        result
      end

      # Allows setting user/group owner using key/value pairs.  If no value is
      # given for user or group, nothing will be changed.
      #
      # @param [String] :user_name Name of the user to make owner.
      # @param [Fixnum] :uid UID of the user to make owner.
      # @param [String] :group_name Name of the group to make owner.
      # @param [Fixnum] :gid GID of the group to make owner.
      # @return [0]
      def chown(watched_object,uid: nil, gid: nil)
        old_uid = self.uid
        old_gid = self.gid
        result = adapter.chown(uid: uid, gid: gid)

        if result == 1
          if (uid && uid != old_uid) || (gid && gid != old_gid)
            watched_object.changed
            watched_object.notify_observers(watched_object,
              attribute: :owner,
              old: { uid: old_uid, gid: old_gid }, new: { uid: uid, gid: gid },
              as_sudo: nil
            )
          end
        end

        0
      end

      def ctime
        adapter.ctime
      end

      def delete(watched_object)
        existed_before = adapter.exists?
        result = adapter.delete

        if result == 1 && existed_before
          watched_object.changed
          watched_object.notify_observers(watched_object,
            attribute: :exists,
            old: true, new: false, as_sudo: nil
          )
        end
      end

      def dirname
        adapter.dirname
      end

      def expand_path(dir_string=nil)
        if dir_string
          adapter.expand_path(dir_string)
        else
          adapter.expand_path
        end
      end

      def extname
        adapter.extname
      end

      def fnmatch(pattern, *flags)
        adapter.fnmatch(pattern, *flags)
      end

      def ftype
        adapter.ftype
      end

      def lchmod(mode_int, watched_object)
=begin
        old_mode = sprintf('%o', File.stat(@path).mode)
        result = File.lchmod(mode_int, @path)
=end
        old_mode = adapter.mode
        result = adapter.lchmod(mode_int)

        if result == 1 && mode_int != old_mode.to_i
          watched_object.changed
          watched_object.notify_observers(watched_object,
            attribute: :lmode,
            old: old_mode, new: mode_int, as_sudo: nil
          )
        end

        result
      end

      def lchown(uid, gid, watched_object)
        old_uid = self.uid
        old_gid = self.gid
        result = adapter.lchown(uid, gid)

        if result == 1
          if (uid && uid != old_uid) || (gid && gid != old_gid)
            watched_object.changed
            watched_object.notify_observers(watched_object,
              attribute: :owner,
              old: { uid: old_uid, gid: old_gid }, new: { uid: uid, gid: gid },
              as_sudo: nil
            )
          end
        end

        0
      end

      def link(new_path, watched_object)
        does_not_exist_before = adapter.exists?
        adapter.link(new_path)

        if does_not_exist_before
          watched_object.changed
          watched_object.notify_observers(watched_object,
            attribte: :hard_link,
            old: nil, new: new_path, as_sudo: nil
          )
        end

        0
      end

      def lstat
        adapter.lstat
      end

      def mtime
        adapter.mtime
      end

=begin
      def open(mode, *options, &block)
        File.open(@path, options, block)
      end
=end
      def path
        adapter.path
      end

      def readlink
        adapter.readlink
      end

      def realdirpath(dir_path=nil)
        if dir_path
          adapter.realdirpath(dir_path)
        else
          adapter.realdirpath
        end
      end

      def realpath(dir_path=nil)
        if dir_path
          adapter.realpath(dir_path)
        else
          adapter.realpath
        end
      end

      def rename(new_name, watched_object)
        old_name = @path
        adapter.rename(new_name)
        @path = new_name

        if old_name != new_name
          watched_object.changed
          watched_object.notify_observers(watched_object,
            attribute: :name,
            old: old_name, new: new_name, as_sudo: nil
          )
        end
      end

      def split
        adapter.split
      end

      def stat
        adapter.stat
      end

      def symlink(new_path, watched_object)
        does_not_exist_before = adapter.exists?
        adapter.symlink(new_path)

        if does_not_exist_before
          watched_object.changed
          watched_object.notify_observers(watched_object,
            attribte: :symbolic_link,
            old: nil, new: new_path, as_sudo: nil
          )
        end

        0
      end

      def truncate(new_length, watched_object)
        old_length = adapter.size
        adapter.truncate(new_length)

        if old_length != new_length
          watched_object.changed
          watched_object.notify_observers(watched_object,
            attribute: :size,
            old: old_length, new: new_length, as_sudo: nil
          )
        end

        0
      end

      def utime(access_time, modification_time, watched_object)
        old_atime = adapter.atime
        old_mtime = adapter.mtime
        adapter.utime(access_time, modification_time)

        if old_atime != access_time
          watched_object.changed
          watched_object.notify_observers(watched_object,
            attribute: :access_time,
            old: old_atime, new: access_time, as_sudo: nil
          )
        end

        if old_mtime != modification_time
          watched_object.changed
          watched_object.notify_observers(self,
            attribute: :modification_time,
            old: old_mtime, new: modification_time, as_sudo: nil
          )
        end
      end

      def flock(lock_types)
        adapter.flock(lock_types)
      end
    end
  end
end
