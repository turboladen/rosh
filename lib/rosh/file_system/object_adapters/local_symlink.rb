require_relative 'local_base'


class Rosh
  class FileSystem
    module ObjectAdapters
      module LocalSymlink
        include LocalBase

        def chmod(mode_int)
          result = ::File.lchmod(mode_int, @path)

          private_result(result, 0)
        end

        def chown(new_uid: nil, new_gid: nil)
          result = ::File.lchown(new_uid, new_gid, @path)

          private_result(result, 0)
        end

        def destination
          f = ::File.readlink(@path)

          private_result(FileSystem::File.new(f, @host_name), 0)
        end

        def link_to(destination)
          result = ::File.symlink(destination, @path)
          exit_status = result.zero? ? 0 : 1

          private_result(result.zero?, exit_status)
        end

        def stat
          result = ::File.lstat(@path)

          private_result(result, 0)
        end
      end
    end
  end
end
