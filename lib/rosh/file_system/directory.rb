require_relative 'file_system_object'


class Rosh
  class FileSystem
    class Directory
      include FileSystemObject

      def initialize(path, host_name)
        @path = path
        @host_name = host_name

        load_strategy
      end

      def load_strategy
        if current_host.local?
          require_relative 'file_system_objects/local_dir'
          extend FileSystem::FileSystemObjects::LocalDir
        else
          #require_relative 'file_system_objects/remote_file'
          #extend FileSystemObjects::RemoteFile
        end
      end
    end
  end
end
