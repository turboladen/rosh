require_relative 'base_methods'
require_relative 'stat_methods'
require_relative '../changeable'
require_relative '../observable'


class Rosh
  class FileSystem
    class BlockDevice
      include BaseMethods
      include StatMethods
      include Rosh::Changeable

      def initialize(path, host_name)
        @path = path
        @host_name = host_name
      end

      private

      def adapter
        return @adapter if @adapter

        @adapter = if current_host.local?
          require_relative 'adapters/local_blockdev'
          FileSystem::Adapters::LocalBlockdev
        else
          require_relative 'adapters/remote_blockdev'
          FileSystem::Adapters::RemoteBlockdev
        end

        @adapter.path = @path
        @adapter.host_name = @host_name

        @adapter
      end
    end
  end
end
