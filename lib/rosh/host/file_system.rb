require_relative 'file_system_objects/local_base'
require_relative 'file_system_objects/remote_base'


class Rosh
  class Host
    class FileSystem
      def initialize(host_name)
        @host_name = host_name
      end

      def [](path)
        if current_host.local?
          FileSystemObjects::LocalBase.create(path)
        else
          FileSystemObjects::RemoteBase.create(path, @host_name)
        end
      end

      def directory(path)
        if current_host.local?
          FileSystemObjects::LocalDir.new(path)
        else
          FileSystemObjects::RemoteDir.new(path, @host_name)
        end
      end

      def file(path)
        if current_host.local?
          FileSystemObjects::LocalFile.new(path)
        else
          FileSystemObjects::RemoteFile.new(path, @host_name)
        end
      end

      def link(path)
        if current_host.local?
          FileSystemObjects::LocalLink.new(path)
        else
          FileSystemObjects::RemoteLink.new(path, @host_name)
        end
      end
    end
  end
end
