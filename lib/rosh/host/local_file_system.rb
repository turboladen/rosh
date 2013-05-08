require_relative 'file_system_objects/local_base'


class Rosh
  class Host
    class LocalFileSystem
      attr_reader :last_command_result

      def initialize
        @last_command_result = nil
      end

      def [](fs_object)
        LocalBase.create(fs_object)
      end
    end
  end
end
