require_relative 'file_system_objects/remote_base'


class Rosh
  class Host
    class RemoteFileSystem
      def initialize(shell)
        @shell = shell
        @last_command_result = nil
      end

      def [](fs_object)
        RemoteBase.new(fs_object, @shell)
      end

      def directory(path)
        Rosh::Host::FileSystemObjects::RemoteDir.new(path, @shell)
      end

      def file(path)
        Rosh::Host::FileSystemObjects::RemoteFile.new(path, @shell)
      end

      def link(path)
        Rosh::Host::FileSystemObjects::RemoteLink.new(path, @shell)
      end
    end
  end
end
