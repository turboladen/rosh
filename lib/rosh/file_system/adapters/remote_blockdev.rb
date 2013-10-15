require_relative 'remote_base'


class Rosh
  class FileSystem
    module Adapters
      class RemoteBlockdev
        include RemoteBase
      end
    end
  end
end
