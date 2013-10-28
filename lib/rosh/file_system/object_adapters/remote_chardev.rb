require_relative 'remote_base'


class Rosh
  class FileSystem
    module ObjectAdapters
      module RemoteChardev
        include RemoteBase
      end
    end
  end
end
