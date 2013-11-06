require_relative 'remote_base'


class Rosh
  class FileSystem
    module ObjectAdapters
      module RemoteSymlink
        include RemoteBase

        # @param [String,Integer] mode_int
        # @return [Boolean]
        def chmod(mode_int)
          if current_host.darwin?
            current_shell.exec_internal("chmod -h #{mode_int} #{@path}")
          else
            current_shell.exec_internal("chmod #{mode_int} #{@path}")
          end

          current_shell.last_exit_status.zero?
        end

        # @param [String,Integer] uid
        # @param [String,Integer] gid
        # @return [Boolean]
        def chown(uid, gid=nil)
          cmd = if current_host.darwin?
            "chown -h #{uid}"
          else
            "chown #{uid}"
          end

          cmd << ":#{gid}" if gid
          cmd << " #{@path}"
          current_shell.exec_internal cmd


          current_shell.last_exit_status.zero?
        end

        def destination
          f = current_shell.exec_internal "readlink #{@path}"

          FileSystem::File.new(f.strip, @host_name)
        end

        def link_to(destination)
          current_shell.exec_internal "ln -s #{destination} #{@path}"

          current_shell.last_exit_status.zero?
        end

        # @return [Boolean] +true+ if the object exists on the file system;
        #   +false+ if not.
        def exists?
          cmd = "test -L #{@path}"
          current_shell.exec_internal(cmd)

          current_shell.last_exit_status.zero?
        end

        # @return [String]
        def stat
          result = current_shell.exec_internal "stat #{@path}"
        end
      end
    end
  end
end
