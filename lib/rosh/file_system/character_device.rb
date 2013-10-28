require_relative '../changeable'
require_relative '../observable'
require_relative 'base_methods'
require_relative 'stat_methods'
require_relative 'object_adapter'


class Rosh
  class FileSystem
    class CharacterDevice
      include BaseMethods
      include StatMethods
      include Rosh::Changeable
      include Rosh::Observable

      def initialize(path, host_name)
        @path = path
        @host_name = host_name
      end

      private

      def adapter
        return @adapter if @adapter

        type = if current_host.local?
          :local_chardev
        else
          :remote_chardev
        end

        @adapter = FileSystem::ObjectAdapter.new(@path, type, @host_name)
      end
    end
  end
end
