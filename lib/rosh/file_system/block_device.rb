require_relative 'base_methods'
require_relative 'stat_methods'
require_relative 'object_adapter'


class Rosh
  class FileSystem
    class BlockDevice
      include BaseMethods
      include StatMethods

      def initialize(path, host_name)
        @path = path
        @host_name = host_name
      end

      private

      def adapter
        return @adapter if @adapter

        type = if current_host.local?
          :local_blockdev
        else
          :remote_blockdev
        end

        @adapter = FileSystem::ObjectAdapter.new(@path, type, @host_name)
      end
    end
  end
end
