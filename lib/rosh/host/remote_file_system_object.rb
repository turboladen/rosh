
class Rosh
  class Host
    class RemoteFileSystemObject
      def self.create(path, remote_shell)
        fso = new(path, remote_shell)

        if fso.directory?
          Rosh::RemoteDir.new(path, remote_shell)
        elsif fso.file?
          Rosh::RemoteFile.new(path, remote_shell)
        elsif fso.link?
          Rosh::RemoteLink.new(path, remote_shell)
        end
      end

      def initialize(path, remote_shell)
        @path = path
        @remote_shell = remote_shell
      end

      def to_path
        @path
      end

      def file?
        cmd = "[ -f #{@path} ]"
        result = @remote_shell.run(cmd)

        result.ssh_result.exit_code.zero?
      end

      def directory?
        cmd = "[ -d #{@path} ]"
        result = @remote_shell.run(cmd)

        result.ssh_result.exit_code.zero?
      end

      def link?
        cmd = "[ -L #{@path} ]"
        result = @remote_shell.run(cmd)

        result.ssh_result.exit_code.zero?
      end

      def exists?
        cmd = "[ -e #{@path} ]"
        result = @remote_shell.run(cmd)

        result.ssh_result.exit_code.zero?
      end

      def owner
        cmd = "ls -l #{@path} | awk '{print $3}'"
        result = @remote_shell.run(cmd)

        result.ssh_result.stdout.strip
      end

      def owner=(new_owner, sudo: false)
        cmd = "chown #{new_owner} #{@path}"
        cmd.insert(0, 'sudo ') if sudo
        result = @remote_shell.run(cmd)

        result.ssh_result.exit_code.zero?
      end

      def group
        cmd = "ls -l #{@path} | awk '{print $4}'"
        result = @remote_shell.run(cmd)

        result.ssh_result.stdout.strip
      end
    end
  end
end

require_relative 'remote_dir'
require_relative 'remote_file'
require_relative 'remote_link'
