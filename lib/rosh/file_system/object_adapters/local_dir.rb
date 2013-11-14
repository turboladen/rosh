require_relative 'local_base'


class Rosh
  class FileSystem
    module ObjectAdapters

      # Represents a directory on the local file system.
      module LocalDir
        include LocalBase

        # @return [Array<Rosh::Host::Adapters>]
        def entries
          handle_errors_and_return_result do
            ::Dir.entries(@path).map do |entry|
              next if %w[. ..].include?(entry)
              Rosh::FileSystem.create("#{@path}/#{entry}", @host_name)
            end.compact
          end
        end

        # Opens the directory, passes it to the block, then closes it.
        def open(&block)
          handle_errors_and_return_result do
            ::Dir.open(@path, &block)
          end
        end

        def mkdir
          handle_errors_and_return_result do
            result = ::Dir.mkdir(@path)

            result.zero?
          end
        end

        def rmdir
          handle_errors_and_return_result do
            result = ::Dir.rmdir(@path)

            result.zero?
          end
        end
      end
    end
  end
end
