require 'observer'
require_relative 'base_methods'
require_relative 'api_stat'
require_relative '../changeable'
require_relative '../observable'


class Rosh
  class FileSystem
    class Object
      include BaseMethods
      include APIStat
      include Rosh::Changeable
      include Rosh::Observable

      def initialize(path, host_name)
        @path = path
        @host_name = host_name
      end

      def to_file
        require_relative 'file'
        Rosh::FileSystem::File.new(@path, @host_name)
      end

      def to_directory
        require_relative 'directory'
        Rosh::FileSystem::Directory.new(@path, @host_name)
      end

      def to_link
        require_relative 'link'
        Rosh::FileSystem::Link.new(@path, @host_name)
      end
    end
  end
end
