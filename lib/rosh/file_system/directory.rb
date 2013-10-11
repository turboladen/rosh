require 'observer'
require_relative 'api_base'
require_relative 'api_stat'
require_relative '../changeable'


class Rosh
  class FileSystem
    class Directory
      include Observable
      include APIBase
      include APIStat
      include Rosh::Changeable

      def initialize(path, host_name)
        @path = path
        @host_name = host_name
      end

      def create
        change_if(exists?) do
          notify_about(self, :exists?, from: false, to: true) do
            adapter.mkdir
          end
        end
      end

      def delete
        change_if(!exists?) do
          notify_about(self, :exists?, from: true, to: false) do
            adapter.rmdir
          end
        end
      end
      alias_method :remove, :delete
      alias_method :unlink, :delete

      def entries
        adapter.entries
      end

      def each(&block)
        adapter.entries.each(&block)
      end

      # @todo Add #glob.
      def glob
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

        @adapter = if current_host.local?
          require_relative 'adapters/local_dir'
          FileSystem::Adapters::LocalDir
        else
          require_relative 'adapters/remote_dir'
          FileSystem::Adapters::RemoteDir
        end

        @adapter.path = @path
        @adapter.host_name = @host_name

        @adapter
      end
    end
  end
end
