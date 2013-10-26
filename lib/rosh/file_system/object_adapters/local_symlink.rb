require_relative 'local_base'


class Rosh
  class FileSystem
    module ObjectAdapters
      class LocalSymlink
        include LocalBase

        class << self
          def chmod(mode_int)
            ::File.lchmod(mode_int, @path)
          end

          def chown(new_uid: nil, new_gid: nil)
            ::File.lchown(new_uid, new_gid, @path)
          end

          def stat
            ::File.lstat(@path)
          end
        end
      end
    end
  end
end
