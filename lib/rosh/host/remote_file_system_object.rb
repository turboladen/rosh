
class Rosh
  class Host
    class RemoteFileSystemObject
      def self.create(path, remote_shell)
        fso = new(path, remote_shell)

        if fso.directory?
          Rosh::Host::RemoteDir.new(path, remote_shell)
        elsif fso.file?
          Rosh::Host::RemoteFile.new(path, remote_shell)
        elsif fso.link?
          Rosh::Host::RemoteLink.new(path, remote_shell)
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
        @remote_shell.exec(cmd)

        @remote_shell.last_exit_status.zero?
      end

      def directory?
        cmd = "[ -d #{@path} ]"
        @remote_shell.exec(cmd)

        @remote_shell.last_exit_status.zero?
      end

      def link?
        cmd = "[ -L #{@path} ]"
        @remote_shell.exec(cmd)

        @remote_shell.last_exit_status.zero?
      end

      def exists?
        cmd = "[ -e #{@path} ]"
        @remote_shell.exec(cmd)

        @remote_shell.last_exit_status.zero?
      end

      def owner
        cmd = "ls -l #{@path} | awk '{print $3}'"

        @remote_shell.exec(cmd)
      end

      def owner=(new_owner, sudo: false)
        cmd = "chown #{new_owner} #{@path}"
        cmd.insert(0, 'sudo ') if sudo
        @remote_shell.exec(cmd)

        @remote_shell.last_exit_status.zero?
      end

      def group
        #cmd = "ls -l #{@path} | awk '{print $4}'"
        cmd = "M=`stat -f %g% #{@path}` && cat /etc/group | grep :$M:"
        output = @remote_shell.exec(cmd)
        puts "output: #{output}"

        %r[(?<group_name>)] =~ output

        group_name
      end

      def group=(new_group, sudo: false)
        cmd = "chgrp #{new_group} #{@path}"
        cmd.insert(0, 'sudo ') if sudo
        @remote_shell.exec(cmd)

        @remote_shell.last_exit_status.zero?
      end

      def mode=(new_mode, sudo: false)
        cmd = "chmod #{new_mode} #{@path}'"
        cmd.insert(0, 'sudo ') if sudo
        @remote_shell.exec(cmd)

        @remote_shell.last_exit_status.zero?
      end

      def basename
        File.basename(@path)
      end

      def remove(sudo: false)
        cmd = "rm -rf #{@path}"
        cmd.insert(0, 'sudo ') if sudo
        @remote_shell.exec(cmd)

        @remote_shell.last_exit_status.zero?
      end
    end
  end
end

require_relative 'remote_dir'
require_relative 'remote_file'
require_relative 'remote_link'
