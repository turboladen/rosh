require_relative 'local_base'


class Rosh
  class FileSystem
    module ObjectAdapters
      module LocalSymlink
        include LocalBase

        def chmod(mode_int)
          ::File.lchmod(mode_int, @path)
        end

        def chown(new_uid: nil, new_gid: nil)
          ::File.lchown(new_uid, new_gid, @path)
        end

        def destination
          f = ::File.readlink(@path)

          FileSystem::File.new(f, @host_name)
        end

        def link_to(destination)
          result = ::File.symlink(destination, @path)

          result.zero?
        end

        def stat
          ::File.lstat(@path)
        end
      end
    end
  end
end
