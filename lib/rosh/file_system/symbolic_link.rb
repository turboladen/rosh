require_relative 'base_methods'
require_relative 'stat_methods'
require_relative 'object_adapter'
require_relative 'state_machine'
require_relative '../command'
require_relative '../host_methods'

class Rosh
  class FileSystem
    class SymbolicLink
      include BaseMethods
      include StatMethods
      include StateMachine
      include Rosh::HostMethods

      def initialize(path, host_name)
        @path = path
        @host_name = host_name
      end

      def destination
        Rosh._run_command(method(__method__), &adapter.method(__method__).to_proc)
      end

      def link_to(new_destination)
        echo_rosh_command new_destination

        Rosh._run_command(method(__method__), new_destination, &adapter.method(__method__).to_proc)
      end

      private

      def adapter
        return @adapter if @adapter

        type = if Rosh.environment.current_host.local?
                 :local_symlink
               else
                 :remote_symlink
        end

        @adapter = FileSystem::ObjectAdapter.new(@path, type, @host_name)
      end
    end
  end
end
