require_relative 'file_controller'
require_relative 'api_base'
require_relative 'api_stat'


class Rosh
  class FileSystem
    class File
      include APIBase
      include APIStat

      def initialize(path, host_name)
        @path = path
        @host_name = host_name
      end

      def controller
        @controller ||= FileController.new(@path, @host_name)
      end
    end
  end
end
