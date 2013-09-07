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

        @adapter
      end
    end
  end
end
