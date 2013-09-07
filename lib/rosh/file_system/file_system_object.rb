require 'observer'
require_relative '../string_refinements'


class Rosh
  class FileSystem
    # TODO: Add IO methods.
    module FileSystemObject
      include Observable

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
        not_implemented
      end

      def atime
        not_implemented
      end

      # Just like Ruby's File#basename, returns the base name of the object.
      #
      # @param [String] suffix
      # @return [String]
      def basename(suffix=nil)
        not_implemented
      end

      def change_mode_to(mode_int)
        old_mode = mode
        result = _chmod(mode_int)

        if result == 1 && mode_int != old_mode.to_i
          changed
          notify_observers(self,
            attribute: :mode,
            old: old_mode, new: mode_int, as_sudo: nil
          )
        end

        result
      end
      alias_method :chmod, :change_mode_to

      # Allows setting user/group owner using key/value pairs.  If no value is
      # given for user or group, nothing will be changed.
      #
      # @param [String] :user_name Name of the user to make owner.
      # @param [Fixnum] :uid UID of the user to make owner.
      # @param [String] :group_name Name of the group to make owner.
      # @param [Fixnum] :gid GID of the group to make owner.
      # @return [0]
      def chown(uid: nil, gid: nil)
        old_uid = self.uid
        old_gid = self.gid
        result = _chown(uid: uid, gid: gid)

        if result == 1
          if (uid && uid != old_uid) || (gid && gid != old_gid)
            changed
            notify_observers(self,
              attribute: :owner,
              old: { uid: old_uid, gid: old_gid }, new: { uid: uid, gid: gid },
              as_sudo: nil
            )
          end
        end

        0
      end
      alias_method :owner, :chown

      def change_time
        ctime
      end
      alias_method :ctime, :change_time

      def delete
        existed_before = exists?
        result = _delete

        if result == 1 && existed_before
          changed
          notify_observers(self,
            attribute: :exists,
            old: true, new: false, as_sudo: nil
          )
        end
      end
      alias_method :unlink, :delete

      def expand_path(dir_string=nil)
        not_implemented
      end

      def extension
        extname
      end
      alias_method :extname, :extension

      def file_name_match(pattern, *flags)
        fnmatch(pattern, *flags)
      end
      alias_method :fnmatch, :file_name_match
      alias_method :fnmatch?, :file_name_match

      def file_type
        ftype
      end
      alias_method :ftype, :file_type

      def lchmod(mode_int)
=begin
        old_mode = sprintf('%o', File.stat(@path).mode)
        result = File.lchmod(mode_int, @path)
=end
        old_mode = mode
        result = _lchmod(mode_int)

        if result == 1 && mode_int != old_mode.to_i
          changed
          notify_observers(self,
            attribute: :lmode,
            old: old_mode, new: mode_int, as_sudo: nil
          )
        end

        result
      end

      def lchown(uid: nil, gid: nil)
        old_uid = self.uid
        old_gid = self.gid
        result = _lchown(uid: uid, new_gid: gid)

        if result == 1
          if (uid && uid != old_uid) || (gid && gid != old_gid)
            changed
            notify_observers(self,
              attribute: :owner,
              old: { uid: old_uid, gid: old_gid }, new: { uid: uid, gid: gid },
              as_sudo: nil
            )
          end
        end

        0
      end

      def hard_link_to(new_path)
        does_not_exist_before = exists?
        _link(new_path)

        if does_not_exist_before
          changed
          notify_observers(self,
            attribte: :hard_link,
            old: nil, new: new_path, as_sudo: nil
          )
        end

        0
      end
      alias_method :link, :hard_link_to

      def lstat
        not_implemented
      end

      def modification_time
        mtime
      end
      alias_method :mtime, :modification_time

=begin
      def open(mode, *options, &block)
        File.open(@path, options, block)
      end
=end
      def path
        not_implemented
      end

      def read_link
        readlink
      end
      alias_method :readlink, :read_link

      def real_dir_path(dir_path=nil)
        realdirpath
      end
      alias_method :realdirpath, :real_dir_path

      def real_path(dir_path=nil)
        realpath
      end
      alias_method :realpath, :real_path

      def rename_to(new_name)
        old_name = @path
        _rename(new_name)
        @path = new_name

        if old_name != new_name
          changed
          notify_observers(self,
            attribute: :name,
            old: old_name, new: new_name, as_sudo: nil
          )
        end
      end
      alias_method :rename, :rename_to

      def split
        not_implemented
      end

      def stat
        not_implemented
      end

      def symbolic_link_to
        symlink
      end
      alias_method :symlink, :symbolic_link_to

      def truncate(new_length)
        old_length = size
        _truncate(new_length)

        if old_length != new_length
          changed
          notify_observers(self,
            attribute: :size,
            old: old_length, new: new_length, as_sudo: nil
          )
        end

        0
      end

      def file_times=(access_time, modification_time)
        old_atime = atime
        old_mtime = mtime
        _utime(access_time, modification_time)

        if old_atime != access_time
          changed
          notify_observers(self,
            attribute: :access_time,
            old: old_atime, new: access_time, as_sudo: nil
          )
        end

        if old_mtime != modification_time
          changed
          notify_observers(self,
            attribute: :modification_time,
            old: old_mtime, new: modification_time, as_sudo: nil
          )
        end
      end
      alias_method :utime, :file_times=

      def lock(lock_types)
        flock(lock_types)
      end
      alias_method :flock, :lock

      #------------------------------------------------------------------------
      # File::Stat methods
      #------------------------------------------------------------------------
      def exists?
        not_implemented
      end

      def <=>(_)
        not_implemented
      end

      def block_size
        blksize
      end
      alias_method :blksize, :block_size

      def block_device?
        blockdev?
      end
      alias_method :blockdev?, :block_device?

      def blocks
        not_implemented
      end

      def character_device?
        chardev?
      end
      alias_method :chardev?, :character_device?

      def device
        dev
      end
      alias_method :dev, :device

      def device_major
        dev_major
      end
      alias_method :dev_major, :device_major

      def device_minor
        dev_minor
      end
      alias_method :dev_minor, :device_minor

      def directory?
        not_implemented
      end

      def executable?
        not_implemented
      end

      def executable_real?
        not_implemented
      end

      def file?
        not_implemented
      end

      def gid
        not_implemented
      end

      def group_owned?
        grpowned?
      end
      alias_method :grpowned?, :group_owned?

      def inode
        ino
      end
      alias_method :ino, :inode

      def inspect
        not_implemented
      end

      def mode
        not_implemented
      end

      def nlink
        not_implemented
      end

      def owned?
        not_implemented
      end

      def pipe?
        not_implemented
      end

      def rdev
        not_implemented
      end

      def rdev_major
        not_implemented
      end

      def rdev_minor
        not_implemented
      end

      def readable?
        not_implemented
      end

      def readable_real?
        not_implemented
      end

      def set_group_id?
        setgid?
      end
      alias_method :setgid?, :set_group_id?

      def set_user_id?
        setuid?
      end
      alias_method :setuid?, :set_user_id?

      def size
        not_implemented
      end

      def socket?
        not_implemented
      end

      def sticky?
        not_implemented
      end

      def symbolic_link?
        not_implemented
      end
      alias_method :symlink?, :symbolic_link?

      def user_id
        uid
      end
      alias_method :uid, :user_id

      def world_readable?
        not_implemented
      end

      def world_writable?
        not_implemented
      end

      def writable?
        not_implemented
      end

      def writable_real?
        not_implemented
      end

      def zero?
        not_implemented
      end

      # Called by serializer when dumping.
      def encode_with(coder)
        coder['type'] = @type
        coder['path'] = @path
        coder['host_name'] = @host_name
      end

      # Called by serializer when loading.
      def init_with(coder)
        @type = coder['type']
        @path = coder['path']
        @host_name = coder['host_name']
      end

      private

      def load_strategy(type)
        if type.to_s.match /local/
          require_relative 'file_system_objects/local_base'
          extend Rosh::Host::FileSystemObjects::LocalBase
        else
          require_relative 'file_system_objects/remote_base'
          extend Rosh::Host::FileSystemObjects::RemoteBase
        end

        #require_relative "file_system_objects/#{type}"
        #fso_module = Rosh::Host::FileSystemObjects.const_get(type.to_s.classify)

        #extend fso_module
      end

      def not_implemented
        warn 'Not implemented!'
      end
    end
  end
end
