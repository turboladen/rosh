require_relative 'local_base'


class Rosh
  class Host
    module FileSystemObjects
      class LocalFile < LocalBase
        undef_method :readlink
      end
    end
  end
end
