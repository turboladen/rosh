require_relative 'local_file_system_object'


class Rosh
  class LocalDir < LocalFileSystemObject
    undef_method :readlink
    undef_method :truncate
  end
end
