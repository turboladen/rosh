require 'observer'
require_relative 'base_methods'
require_relative 'stat_methods'
require_relative '../changeable'
require_relative '../observable'

class Rosh
  class FileSystem
    class SymbolicLink
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

        @adapter = if current_host.local?
          require_relative 'object_adapters/local_symlink'
          FileSystem::ObjectAdapters::LocalSymlink
        else
          require_relative 'object_adapters/remote_symlink'
          FileSystem::ObjectAdapters::RemoteSymlink
        end

        @adapter.path = @path
        @adapter.host_name = @host_name

        @adapter
      end
    end
  end
end
