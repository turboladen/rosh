require_relative 'local_base'


class Rosh
  class FileSystem
    module Adapters

      # Represents a directory on the local file system.
      class LocalDir
        include LocalBase

        class << self

          # @return [Array<Rosh::Host::Adapters>]
          def entries(host_name)
            ::Dir.entries(@path).map do |entry|
              next if %w[. ..].include?(entry)
              Rosh::FileSystem.create("#{@path}/#{entry}", host_name)
            end.compact
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
end
