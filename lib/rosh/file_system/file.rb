require 'observer'
require_relative 'file_controller'
require_relative 'api_base'
require_relative 'api_stat'


class Rosh
  class FileSystem

    # A Rosh::FileSystem::File can represent either a file on a local host or a
    # remote host.  It allows you to interact with a file on your file system
    # in an object-oriented manner.
    #
    # Additionally, Files are observable: they can notify other objects when
    # they change.  Observing objects must have an #update method defined that
    # takes parameter list: `(changed_file, attribute: nil, old: nil, new: nil,
    # as_sudo: nil)`.
    #
    #   class MyWatcher
    #     def update(changed_file, attribute: nil, old: nil, new: nil, as_sudo: nil)
    #       puts "File '#{changed_file.path}' changed:"
    #       puts "  attribute:  #{attribute}"
    #       puts "  old value:  #{old}"
    #       puts "  new value:  #{new}"
    #       puts "  using sudo? #{as_sudo}
    #     end
    #   end
    #
    #   watcher = MyWatcher.new
    #   file = Rosh::FileSystem::File.new('/tmp/my_file', 'my_host.com')
    #   file.add_observer(watcher)
    #   file.mode           # => 755
    #   file.chmod(644)
    #   # =>  "File '/tmp/my_file' changed:"
    #   #     "  attribute:  :mode"
    #   #     "  old value:  755"
    #   #     "  new value:  644"
    #   #     "  using sudo? false"
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
        @controller ||= FileController.new(@path, @host_name)
      end
    end
  end
end
