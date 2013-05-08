require_relative 'file_system_objects/local_base'
require_relative 'file_system_objects/remote_base'


class Rosh
  class Host
    class FileSystem
      def initialize(shell=nil, remote=true)
        @shell = shell
        @remote = remote
        @last_command_result = nil
      end

      def [](path)
        if remote
          RemoteBase.create(path, @shell)
        else
          LocalBase.create(path)
        end
      end

      def directory(path)
        if remote
          FileSystemObjects::RemoteDir.new(path, @shell)
        else
          FileSystemObjects::LocalDir.new(path)
        end
      end

      def file(path)
        if remote
          FileSystemObjects::RemoteFile.new(path, @shell)
        else
          FileSystemObjects::LocalFile.new(path)
        end
      end

      def link(path)
        if remote
          FileSystemObjects::RemoteLink.new(path, @shell)
        else
          FileSystemObjects::LocalLink.new(path)
        end
      end
    end
  end
end
