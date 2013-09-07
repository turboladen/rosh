require_relative 'local_base'


class Rosh
  class FileSystem
    module Adapters

      # Represents a directory on the local file system.
      class LocalDir
        include LocalBase

        # @return [Array<Rosh::Host::Adapters>]
        def entries
          Dir.entries(@path).map do |entry|
            Rosh::FileSystem.create("#{@path}/#{entry}", @host_name)
          end.compact
        end

        # Allows for iterating over each entry in the directory.
        #
        # @return [Enumerator]
        def each
          if block_given?
            entries.each { |entry| yield entry }
          else
            entries.each
          end
        end

        # Opens the directory, passes it to the block, then closes it.
        def open(&block)
          Dir.open(@path, &block)
        end
      end
    end
  end
end
