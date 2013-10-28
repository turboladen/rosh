require_relative 'remote_base'


class Rosh
  class FileSystem
    module ObjectAdapters
      module RemoteBlockdev
        include RemoteBase
      end
    end
  end
end
