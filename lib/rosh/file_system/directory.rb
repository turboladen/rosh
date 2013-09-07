require_relative 'directory_controller'
require_relative 'api_base'
require_relative 'api_stat'


class Rosh
  class FileSystem
    class Directory
      include APIBase
      include APIStat

      def initialize(path, host_name)
        @path = path
        @host_name = host_name
      end

      def create
        controller.mkdir(self)
      end

      def delete
        controller.rmdir(self)
      end
      alias_method :remove, :delete
      alias_method :unlink, :delete

      def entries
        controller.entries
      end

      def each(&block)
        controller.entries.each(&block)
      end

      # @todo Add #glob.
      def glob
        warn 'Not implemented!'
      end

      def controller
        @controller ||= DirectoryController.new(@path, @host_name)
      end
    end
  end
end
