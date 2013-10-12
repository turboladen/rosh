require_relative '../changeable'
require_relative '../observable'


class Rosh
  class FileSystem
    module APIBase
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

      def change_owner_to(uid: nil, gid: nil)
        current_owner = self.uid
        current_group = self.gid
        criteria = []

        if uid
          criteria << -> { uid.to_i != current_owner }
        end

        if gid
          criteria << -> { gid.to_i != current_group }
        end

        change_if criteria do
          notify_about(self, :owner, from: { uid: current_owner, gid: current_group },
            to: { uid: uid, gid: gid }) do
            adapter.chown(uid: uid, gid: gid)
          end
        end
      end
      alias_method :owner=, :change_owner_to
      alias_method :chown, :change_owner_to

      def change_time
        adapter.ctime
      end
      alias_method :ctime, :change_time

      def delete
        change_if(exists?) do
          notify_about(self, :exists?, from: true, to: false) do
            adapter.delete
          end
        end
      end
      alias_method :unlink, :delete

      def dirname
        adapter.dirname
      end

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

      def hard_link_to(new_path)
        new_link = current_host.fs[link: new_path]
        criteria = [
          lambda { !new_link.exists? }
        ]

        change_if criteria do
          notify_about(new_link, :exists?, from: false, to: true) do
            adapter.link(new_path)
          end
        end
      end
      alias_method :link, :hard_link_to

      def modification_time
        adapter.mtime
      end
      alias_method :mtime, :modification_time

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

      def split
        adapter.split
      end

      def stat
        adapter.stat
      end

      # @todo Deal with symlinks vs hard links.
      def symbolic_link_to(new_path)
        adapter.symlink(new_path)
      end
      alias_method :symlink, :symbolic_link_to

      def to_s
        @path.to_s
      end

      def truncate(new_length)
        adapter.truncate(new_length)
      end

      def file_times=(access_time, modification_time)
        adapter.utime(access_time, modification_time)
      end
      alias_method :utime, :file_times=

      def lock(types)
        adapter.flock(types)
      end
      alias_method :flock, :lock
    end
  end
end
