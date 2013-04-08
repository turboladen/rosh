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
    end
  end
end
