require_relative 'local_base'


class Rosh
  class Host
    module FileSystemObjects
      class LocalDir < LocalBase
        undef_method :readlink
        undef_method :truncate


        # @return [Array<Rosh::LocalBase>]
        def entries
          Dir.entries(@path).map do |entry|
            Rosh::Host::FileSystemObjects::LocalBase.create("#{@path}/#{entry}")
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
