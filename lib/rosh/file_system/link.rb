require 'observer'
require_relative 'base_methods'
require_relative 'stat_methods'
require_relative '../changeable'
require_relative '../observable'

class Rosh
  class FileSystem
    class Link
      include BaseMethods
      include StatMethods
      include Rosh::Changeable
      include Rosh::Observable

      def initialize(path, host_name)
        @path = path
        @host_name = host_name
      end
    end
  end
end
