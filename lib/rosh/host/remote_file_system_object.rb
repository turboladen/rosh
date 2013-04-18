require 'observer'


class Rosh
  class Host
    class RemoteFileSystemObject
      include Observable

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

      def owner=(new_owner)
        old_owner = owner
        puts "old owner: #{old_owner}"
        puts "new owner: #{new_owner}"
        cmd = "chown #{new_owner} #{@path}"
        @remote_shell.exec(cmd)

        success = @remote_shell.last_exit_status.zero?

        if success && old_owner != new_owner
          changed
          notify_observers(:owner, new_owner)
        end

        success
      end

      def group
        cmd = "ls -l #{@path} | awk '{print $4}'"

        @remote_shell.exec(cmd)
      end

      def group=(new_group)
        old_group = group
        cmd = "chgrp #{new_group} #{@path}"
        @remote_shell.exec(cmd)

        success = @remote_shell.last_exit_status.zero?

        if success && old_group != new_group
          changed
          notify_observers(:group, new_group)
        end

        success
      end

      def mode
        cmd = "ls -l #{@path} | awk '{print $1}'"
        letter_mode = @remote_shell.exec(cmd)
        puts "letter mode: #{letter_mode}"
        %r[^(?<type>.)(?<user>.{3})(?<group>.{3})(?<others>.{3})] =~ letter_mode

        converter = lambda do |letters|
          value = 0

          letters.chars do |char|
            case char
            when '-' then next
            when 'x' then value += 1
            when 'w' then value += 2
            when 'r' then value += 4
            end
          end

          value.to_s
        end

        number_mode = ''
        number_mode << converter.call(user)
        number_mode << converter.call(group)
        number_mode << converter.call(others)

        number_mode.to_i
      end

      def mode=(new_mode)
        old_mode = mode
        cmd = "chmod #{new_mode} #{@path}"
        @remote_shell.exec(cmd)

        success = @remote_shell.last_exit_status.zero?

        if success && old_mode != new_mode.to_i
          changed
          notify_observers(:mode, new_mode)
        end

        success
      end

      def basename
        File.basename(@path)
      end

      def remove
        cmd = "rm -rf #{@path}"
        @remote_shell.exec(cmd)

        success = @remote_shell.last_exit_status.zero?

        if success
          changed
          notify_observers(:remove, nil)
        end

        success
      end
    end
  end
end

require_relative 'remote_dir'
require_relative 'remote_file'
require_relative 'remote_link'
