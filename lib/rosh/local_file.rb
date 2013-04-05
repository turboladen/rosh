require_relative 'local_file_system_object'


class Rosh
  class LocalFile < LocalFileSystemObject
    undef_method :readlink
  end
end
