require_relative 'base_controller'
require_relative 'stat_controller'


class Rosh
  class FileSystem
    class FileController
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
          require_relative 'adapters/local_file'
          FileSystem::Adapters::LocalFile
        else
          require_relative 'adapters/remote_file'
          FileSystem::Adapters::RemoteFile
        end

        @adapter.path = @path

        @adapter
      end
    end
  end
end
