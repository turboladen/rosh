class Rosh
  class FileSystem
    class FileSystemController
      def initialize(host_name)
        @host_name = host_name
        @root_directory = '/'
      end

      def chroot(new_root, watched_object)
        old_root = @root_directory
        adapter.chroot(new_root)
        @root_directory = new_root

        unless old_root == new_root
          watched_object.changed
          watched_object.notify_observers(watched_object,
            attribute: :fs_root,
            old: old_root, new: new_root, as_sudo: current_shell.su?
          )
        end
      end

      def directory?(path)
        adapter.directory?(path)
      end

      def file?(path)
        adapter.file?(path)
      end

      def home
        adapter.home
      end

      def getwd
        adapter.getwd
      end

      def umask(new_umask=nil, watched_object=nil)
        if new_umask
          old_umask = adapter.umask
          adapter.umask(new_umask)

          if old_umask != new_umask
            watched_object.changed
            watched_object.notify_observers(watched_object,
              attribute: :umask,
              old: old_umask, new: new_umask, as_sudo: current_shell.su?
            )
          end
        else
          adapter.umask
        end
      end

      private

      def adapter
        return @adapter if @adapter

        @adapter = if current_host.local?
          require_relative 'adapters/local_file_system'
          FileSystem::Adapters::LocalFileSystem
        else
          require_relative 'adapters/remote_file_system'
          FileSystem::Adapters::RemoteFileSystem
        end

        @adapter.host_name = @host_name

        @adapter
      end
    end
  end
end
