require_relative 'base_methods'
require_relative 'stat_methods'
require_relative 'object_adapter'

class Rosh
  class FileSystem
    class Directory
      include BaseMethods
      include StatMethods

      def initialize(path, host_name)
        @path = path
        @host_name = host_name
      end

      #       def create
      #         echo_rosh_command
      #
      #         change_if(!exists?) do
      #           notify_about(self, :exists?, from: false, to: true) do
      #             adapter.mkdir
      #           end
      #         end
      #       end

      def delete
        echo_rosh_command

        run_command(-> { self.exists? }) do
          adapter.rmdir
        end
      end
      alias_method :remove, :delete
      alias_method :unlink, :delete

      def entries
        run_command do
          cmd_result = adapter.entries
          cmd_result.string = cmd_result.ruby_object.map(&:to_s).join("\n")

          cmd_result
        end
      end
      alias_method :list, :entries

      def each(&block)
        run_command { adapter.entries.each(&block) }
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
