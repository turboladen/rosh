require_relative 'remote_base'


class Rosh
  class FileSystem
    module Adapters
      class RemoteSymlink
        include RemoteBase

        class << self

          # @param [String,Integer] mode_int
          # @return [Boolean]
          def chmod(mode_int)
            if current_host.darwin?
              current_shell.exec("chmod -h #{mode_int} #{@path}")
            else
              current_shell.exec("chmod #{mode_int} #{@path}")
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

            current_shell.exec cmd

            current_shell.last_exit_status.zero?
          end

          # @return [String]
          def stat
            current_shell.exec "stat #{@path}"
          end
        end
      end
    end
  end
end
