require_relative 'file_system_objects/local_base'
require_relative 'file_system_objects/remote_base'


class Rosh
  class Host
    class FileSystem
      def initialize(host_label)
        @host_label = host_label
      end

      def [](path)
        if Rosh.hosts[@host_label].local?
          FileSystemObjects::LocalBase.create(path)
        else
          FileSystemObjects::RemoteBase.create(path, @host_label)
        end
      end

      def directory(path)
        if Rosh.hosts[@host_label].local?
          FileSystemObjects::LocalDir.new(path)
        else
          FileSystemObjects::RemoteDir.new(path, @host_label)
        end
      end

      def file(path)
        if Rosh.hosts[@host_label].local?
          FileSystemObjects::LocalFile.new(path)
        else
          FileSystemObjects::RemoteFile.new(path, @host_label)
        end
      end

      def link(path)
        if Rosh.hosts[@host_label].local?
          FileSystemObjects::LocalLink.new(path)
        else
          FileSystemObjects::RemoteLink.new(path, @host_label)
        end
      end
    end
  end
end
