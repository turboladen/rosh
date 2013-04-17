require_relative 'remote_file_system_object'


class Rosh
  class Host
    class RemoteFileSystem
      def initialize(shell)
        @shell = shell
        @last_command_result = nil
      end

      def [](fs_object)
        RemoteFileSystemObject.new(fs_object, @shell)
      end

      def directory(path)
        Rosh::Host::RemoteDir.new(path, @shell)
      end

      def file(path)
        Rosh::Host::RemoteFile.new(path, @shell)
      end

      def link(path)
        Rosh::Host::RemoteLink.new(path, @shell)
      end

      def su
        @shell
      end
    end
  end
end
