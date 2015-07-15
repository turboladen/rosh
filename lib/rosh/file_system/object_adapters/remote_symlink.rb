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

          result = current_shell.last_exit_status.zero?
          exit_status = result ? 0 : 1

          private_result(result, exit_status)
        end

        # @param [String,Integer] uid
        # @param [String,Integer] gid
        # @return [Boolean]
        def chown(uid, gid = nil)
          cmd = if current_host.darwin?
                  "chown -h #{uid}"
                else
                  "chown #{uid}"
          end

          cmd << ":#{gid}" if gid
          cmd << " #{@path}"
          current_shell.exec_internal cmd

          result = current_shell.last_exit_status.zero?
          exit_status = result ? 0 : 1

          private_result(result, exit_status)
        end

        def destination
          f = current_shell.exec_internal "readlink #{@path}"
          file = FileSystem::File.new(f.strip, @host_name)

          private_result(file, 0, file.to_s)
        end

        def link_to(destination)
          current_shell.exec_internal "ln -s #{destination} #{@path}"
          result = current_shell.last_exit_status.zero?
          exit_status = result ? 0 : 1

          private_result(result, exit_status)
        end

        # @return [Boolean] +true+ if the object exists on the file system;
        #   +false+ if not.
        def exists?
          cmd = "test -L #{@path}"
          current_shell.exec_internal(cmd)

          result = current_shell.last_exit_status.zero?
          exit_status = result ? 0 : 1

          private_result(result, exit_status)
        end

        # @return [String]
        def stat
          result = current_shell.exec_internal "stat #{@path}"
          exit_status = current_shell.last_exit_status.zero? ? 0 : 1

          private_result(result, exit_status)
        end
      end
    end
  end
end
