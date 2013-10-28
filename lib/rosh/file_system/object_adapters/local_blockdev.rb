require_relative 'local_base'


class Rosh
  class FileSystem
    module ObjectAdapters
      module LocalBlockdev
        include LocalBase
      end
    end
  end
end
