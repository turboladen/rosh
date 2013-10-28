require_relative '../changeable'
require_relative '../observable'


class Rosh
  class FileSystem
    module BaseMethods
      include Rosh::Changeable
      include Rosh::Observable

      # @param [String] dir_string
      def absolute_path(dir_string=nil)
        adapter.absolute_path(dir_string)
      end

      def access_time
        adapter.atime
      end
      alias_method :atime, :access_time

      def access_time=(new_time)
        current_atime = self.access_time
        current_mtime = self.modification_time

        change_if current_atime != new_time do
          notify_about(self, :access_time, from: current_atime, to: new_time) do
            adapter.utime(new_time, current_mtime)
          end
        end
      end

      # Just like Ruby's File#basename, returns the base name of the object.
      #
      # @param [String] suffix
      # @return [String]
      def base_name(suffix=nil)
        adapter.basename(suffix)
      end
      alias_method :basename, :base_name

      def change_mode_to(new_mode)
        current_mode = self.mode
        criteria = -> { !current_mode.to_s.end_with?(new_mode.to_s) }

        change_if(criteria) do
          notify_about(self, :mode, from: current_mode, to: new_mode) do
            adapter.chmod(new_mode)
          end
        end
      end
      alias_method :mode=, :change_mode_to
      alias_method :chmod, :change_mode_to

      def change_time
        adapter.ctime
      end
      alias_method :ctime, :change_time

      def create
        change_if(!exists?) do
          notify_about(self, :exists?, from: false, to: true) do
            adapter.create
          end
        end
      end

      def delete
        change_if(exists?) do
          notify_about(self, :exists?, from: true, to: false) do
            adapter.delete
          end
        end
      end
      alias_method :unlink, :delete

      def directory_name
        adapter.dirname
      end
      alias_method :dirname, :directory_name

      def expand_path(dir_string=nil)
        adapter.expand_path(dir_string)
      end

      def extension
        adapter.extname
      end
      alias_method :extname, :extension

      def file_name_match(pattern, *flags)
        adapter.fnmatch(pattern, *flags)
      end
      alias_method :fnmatch, :file_name_match
      alias_method :fnmatch?, :file_name_match

      def file_type
        adapter.ftype
      end
      alias_method :ftype, :file_type

      # @todo Return a Rosh Group object.
      def group
        warn 'Not implemented'
      end

      def group=(new_group)
        current_group = self.gid
        new_group = new_group.to_i

        change_if(new_group != current_group) do
          notify_about(self, :group, from: current_group, to: new_group) do
            adapter.chown(gid: new_group)
          end
        end
      end

      def modification_time
        adapter.mtime
      end
      alias_method :mtime, :modification_time

      def modification_time=(new_time)
        current_atime = self.access_time
        current_mtime = self.modification_time

        change_if current_mtime != new_time do
          notify_about(self, :modification_time, from: current_mtime, to: new_time) do
            adapter.utime(current_atime, new_time)
          end
        end
      end

      # @todo Return a Rosh User object.
      def owner
        warn 'Not implemented'
      end

      def owner=(new_owner)
        current_owner = self.uid
        new_owner = new_owner.to_i

        change_if(new_owner != current_owner) do
          notify_about(self, :owner, from: current_owner, to: new_owner) do
            adapter.chown(uid: new_owner)
          end
        end
      end

      # Returns the pathname used to create file as a String. Does not normalize
      # the name.
      #
      # @return [String]
      def path
        adapter.path
      end

      def read_link
        adapter.readlink
      end
      alias_method :readlink, :read_link

      def real_dir_path(dir_path=nil)
        adapter.realdirpath(dir_path)
      end
      alias_method :realdirpath, :real_dir_path

      def real_path(dir_path=nil)
        adapter.realpath(dir_path)
      end
      alias_method :realpath, :real_path

      def rename_to(new_name)
        new_object = current_host.fs[object: new_name]
        current_path = self.expand_path

        change_if !new_object.exists? do
          notify_about(self, :path, from: current_path, to: new_name) do
            adapter.rename(new_name)
          end
        end
      end
      alias_method :name=, :rename_to
      alias_method :rename, :rename_to

      def size
        adapter.size
      end

      def split
        adapter.split
      end

      def stat
        adapter.stat
      end

      def symbolic_link_from(new_path)
        new_link = current_host.fs[link: new_path]

        change_if !new_link.exists? do
          notify_about(new_link, :exists?, from: false, to: true) do
            adapter.symlink(new_path)
          end
        end
      end
      alias_method :symlink, :symbolic_link_from

      def to_s
        path.to_s
      end

      def to_path
        adapter.to_path
      end

      def truncate(new_size)
        current_size = self.size

        change_if(new_size < current_size) do
          notify_about(self, :size, from: current_size, to: new_size) do
            adapter.truncate(new_size)
          end
        end
      end

      def file_times=(access_time, modification_time)
        self.access_time = access_time
        self.modification_time = modification_time
      end
      alias_method :utime, :file_times=

      def lock(types)
        adapter.flock(types)
      end
      alias_method :flock, :lock
    end
  end
end
