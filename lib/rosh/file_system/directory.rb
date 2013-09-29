require 'observer'
require_relative 'controllers/directory_controller'
require_relative 'api_base'
require_relative 'api_stat'


class Rosh
  class FileSystem
    class Directory
      include Observable
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

      # Called by serializer when dumping.
      def encode_with(coder)
        coder['path'] = @path
        coder['host_name'] = @host_name
      end

      # Called by serializer when loading.
      def init_with(coder)
        @path = coder['path']
        @host_name = coder['host_name']
      end

      private

      def controller
        @controller ||= DirectoryController.new(@path, @host_name)
      end
    end
  end
end
