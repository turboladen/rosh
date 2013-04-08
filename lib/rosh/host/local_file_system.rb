require_relative 'local_file_system_object'


class Rosh
  class Host
    class LocalFileSystem
      attr_reader :last_command_result

      def initialize
        @last_command_result = nil
      end

      def [](fs_object)
        LocalFileSystemObject.create(fs_object)
      end
    end
  end
end
