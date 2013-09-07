require_relative 'file_system_object'


class Rosh
  class FileSystem
    class File
      include FileSystemObject

      def initialize(path, host_name)
        @path = path
        @host_name = host_name

        load_strategy
      end

      private

      def load_strategy
        if current_host.local?
          require_relative 'file_system_objects/local_file'
          extend FileSystem::FileSystemObjects::LocalFile
        else
          #require_relative 'file_system_objects/remote_file'
          #extend FileSystemObjects::RemoteFile
        end
      end
    end
  end
end
