require_relative 'base_methods'
require_relative 'stat_methods'
require_relative 'object_adapter'


class Rosh
  class FileSystem
    class SymbolicLink
      include BaseMethods
      include StatMethods

      def initialize(path, host_name)
        @path = path
        @host_name = host_name
      end

      def destination
        run_command { adapter.destination }
      end

      def link_to(new_destination)
        echo_rosh_command new_destination

        run_command { adapter.link_to(new_destination) }
      end

      private

      def adapter
        return @adapter if @adapter

        type = if current_host.local?
          :local_symlink
        else
          :remote_symlink
        end

        @adapter = FileSystem::ObjectAdapter.new(@path, type, @host_name)
      end
    end
  end
end
