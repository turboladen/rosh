require_relative 'base_methods'
require_relative 'stat_methods'
require_relative '../changeable'
require_relative '../observable'


class Rosh
  class FileSystem
    class Object
      include BaseMethods
      include StatMethods
      include Rosh::Changeable
      include Rosh::Observable

      def initialize(path, host_name)
        @path = path
        @host_name = host_name
      end

      def exists?
        false
      end

      def entries
        echo_rosh_command
        error = Rosh::ErrorENOENT.new(@path)

        [Rosh::Shell::PrivateCommandResult.new(error, 1), error.message]
      end
      alias_method :list, :entries

      def to_blockdev
        require_relative 'block_device'
        Rosh::FileSystem::BlockDevice.new(@path, @host_name)
      end

      def to_chardev
        require_relative 'character_device'
        Rosh::FileSystem::CharacterDevice.new(@path, @host_name)
      end

      def to_directory
        require_relative 'directory'
        Rosh::FileSystem::Directory.new(@path, @host_name)
      end

      def to_file
        require_relative 'file'
        Rosh::FileSystem::File.new(@path, @host_name)
      end

      def to_symlink
        require_relative 'symbolic_link'
        Rosh::FileSystem::SymbolicLink.new(@path, @host_name)
      end
    end
  end
end
