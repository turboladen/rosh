require_relative 'remote_file_system_object'


class Rosh
  class Host
    class RemoteDir < RemoteFileSystemObject
      def create(sudo: false)
        cmd = "mkdir -p #{@path}"
        cmd.insert(0, 'sudo ') if sudo
        @remote_shell.exec(cmd)

        @remote_shell.last_exit_status.zero?
      end
    end
  end
end
