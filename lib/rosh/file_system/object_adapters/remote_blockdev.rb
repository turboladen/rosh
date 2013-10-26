require_relative 'remote_base'


class Rosh
  class FileSystem
    module ObjectAdapters
      class RemoteBlockdev
        include RemoteBase
      end
    end
  end
end
