require_relative 'local_base'


class Rosh
  class FileSystem
    module ObjectAdapters

      # Represents a directory on the local file system.
      module LocalDir
        include LocalBase

        # @return [Array<Rosh::Host::Adapters>]
        def entries
          begin
            ::Dir.entries(@path).map do |entry|
              next if %w[. ..].include?(entry)
              Rosh::FileSystem.create("#{@path}/#{entry}", @host_name)
            end.compact
          rescue Errno::ENOENT => ex
            raise Rosh::ErrorENOENT, ex.message
          rescue Errno::ENOTDIR => ex
            raise Rosh::ErrorENOTDIR, ex.message
          end
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
