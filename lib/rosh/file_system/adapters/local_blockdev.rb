require_relative 'local_base'


class Rosh
  class FileSystem
    module Adapters
      class LocalBlockdev
        include LocalBase
      end
    end
  end
end
