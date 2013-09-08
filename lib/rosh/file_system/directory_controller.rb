require_relative 'base_controller'
require_relative 'stat_controller'


class Rosh
  class FileSystem
    class DirectoryController
      include BaseController
      include StatController

      def initialize(path, host_name)
        @path = path
        @host_name = host_name
      end

      def entries
        adapter.entries(@host_name)
      end

      def mkdir(watched_object)
        adapter.mkdir

        watched_object.changed
        watched_object.notify_observers(watched_object,
          attribute: :exists,
          old: false, new: true, as_sudo: current_shell.su?
        )

        0
      end

      def rmdir(watched_object)
        adapter.rmdir

        watched_object.changed
        watched_object.notify_observers(watched_object,
          attribute: :exists,
          old: true, new: false, as_sudo: current_shell.su?
        )

        0
      end

      private

      def adapter
        return @adapter if @adapter

        @adapter = if current_host.local?
          require_relative 'adapters/local_dir'
          FileSystem::Adapters::LocalDir
        else
          require_relative 'adapters/remote_dir'
          FileSystem::Adapters::RemoteDir
        end

        @adapter.path = @path
        @adapter.host_name = @host_name

        @adapter
      end
    end
  end
end
