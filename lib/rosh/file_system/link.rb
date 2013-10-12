require 'observer'
require_relative 'api_base'
require_relative 'api_stat'
require_relative '../changeable'
require_relative '../observable'

class Rosh
  class FileSystem
    class Link
      include APIBase
      include APIStat
      include Rosh::Changeable
      include Rosh::Observable

      def initialize(path, host_name)
        @path = path
        @host_name = host_name
      end
    end
  end
end
