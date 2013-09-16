require 'observer'
require_relative 'file_controller'
require_relative 'api_base'
require_relative 'api_stat'


class Rosh
  class FileSystem
    class File
      include Observable
      include APIBase
      include APIStat

      def initialize(path, host_name)
        @path = path
        @host_name = host_name
      end

      def create
        controller.create(self)
      end

      def contents
        controller.read
      end

      def copy_to(destination)
        the_copy = self.class.new(destination, @host_name)

        controller.copy(the_copy, self)
      end

      def read(length=nil, offset=nil)
        controller.read(length, offset)
      end

      def readlines(separator=$/)
        controller.readlines(separator)
      end

      def each_char(&block)
        contents.each_char(&block)
      end

      def each_codepoint(&block)
        contents.each_codepoint(&block)
      end

      def each_line(separator=$/, &block)
        contents.each_line(separator, &block)
      end

      private

      def controller
        @controller ||= FileController.new(@path, @host_name)
      end
    end
  end
end
