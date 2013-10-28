require 'observer'
require_relative '../changeable'
require_relative '../observable'
require_relative 'base_methods'
require_relative 'stat_methods'
require_relative 'object_adapter'


class Rosh
  class FileSystem
    class Directory
      include Observable
      include BaseMethods
      include StatMethods
      include Rosh::Changeable
      include Rosh::Observable

      def initialize(path, host_name)
        @path = path
        @host_name = host_name
      end

      def create
        echo_rosh_command

        change_if(!exists?) do
          notify_about(self, :exists?, from: false, to: true) do
            adapter.mkdir
          end
        end
      end

      def delete
        echo_rosh_command

        change_if(exists?) do
          notify_about(self, :exists?, from: true, to: false) do
            adapter.rmdir
          end
        end
      end
      alias_method :remove, :delete
      alias_method :unlink, :delete

      def entries
        echo_rosh_command

        adapter.entries
      end
      alias_method :list, :entries

      def each(&block)
        adapter.entries.each(&block)
      end

      # @todo Add #glob.
      def glob
        echo_rosh_command

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

      def adapter
        return @adapter if @adapter

        type = if current_host.local?
          :local_dir
        else
          :remote_dir
        end

        @adapter = FileSystem::ObjectAdapter.new(@path, type, @host_name)
      end
    end
  end
end
