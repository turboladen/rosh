require_relative 'base_methods'
require_relative 'stat_methods'


class Rosh
  class FileSystem
    module Controllers
      class FileController
        include BaseMethods
        include StatMethods

        def initialize(path, host_name)
          @path = path
          @host_name = host_name
        end

        def create(watched_object)
          adapter.create

          watched_object.changed
          watched_object.notify_observers(watched_object,
            attribute: :exists,
            old: false, new: true, as_sudo: current_shell.su?
          )
        end

        def copy(destination_object, original_object)
          copy_existed = destination_object.exists?
          dest = destination_object.path
          adapter.copy(dest)

          unless copy_existed
            original_object.changed
            original_object.notify_observers(original_object,
              attribute: :exists,
              old: original_object, new: destination_object,
              as_sudo: current_shell.su?
            )
          end
        end

        def read(length=nil, offset=nil)
          adapter.read(length, offset)
        end

        def readlines(separator)
          adapter.readlines(separator)
        end

        def each_line(separator, &block)
          adapter.each_line(separator, &block)
        end

        private

        def adapter
          return @adapter if @adapter

          @adapter = if current_host.local?
            require_relative 'adapters/local_file'
            FileSystem::Adapters::LocalFile
          else
            require_relative 'adapters/remote_file'
            FileSystem::Adapters::RemoteFile
          end

          @adapter.path = @path
          @adapter.host_name = @host_name

          @adapter
        end
      end
    end
  end
end
