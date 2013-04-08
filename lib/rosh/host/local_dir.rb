require_relative 'local_file_system_object'


class Rosh
  class Host
    class LocalDir < LocalFileSystemObject
      undef_method :readlink
      undef_method :truncate


      # @return [Array<Rosh::LocalFileSystemObject>]
      def entries
        Dir.entries(@path).map do |entry|
          Rosh::Host::LocalFileSystemObject.create(entry)
        end
      end

      def each
        if block_given?
          entries.each { |entry| yield entry }
        else
          entries.each
        end
      end

      def open(&block)
        Dir.open(@path, &block)
      end
    end
  end
end
