require_relative 'local_base'


class Rosh
  class FileSystem
    module Adapters
      class LocalChardev
        include LocalBase
      end
    end
  end
end
