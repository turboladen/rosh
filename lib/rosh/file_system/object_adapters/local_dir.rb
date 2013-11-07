require_relative 'local_base'


class Rosh
  class FileSystem
    module ObjectAdapters

      # Represents a directory on the local file system.
      module LocalDir
        include LocalBase

        # @return [Array<Rosh::Host::Adapters>]
        def entries
          result = begin
            listing = ::Dir.entries(@path).map do |entry|
              next if %w[. ..].include?(entry)
              Rosh::FileSystem.create("#{@path}/#{entry}", @host_name)
            end.compact

            exit_status = 0

            listing
          rescue Errno::ENOENT => ex
            exit_status = 1
            Rosh::ErrorENOENT.new(@path)
          end

          Rosh::Shell::PrivateCommandResult.new(result, exit_status)
        end

        # Opens the directory, passes it to the block, then closes it.
        def open(&block)
          ::Dir.open(@path, &block)
        end

        def mkdir
          result = ::Dir.mkdir(@path)

          result.zero?
        end

        def rmdir
          result = ::Dir.rmdir(@path)

          result.zero?
        end
      end
    end
  end
end
