require 'observer'


class Rosh
  class Host
    class RemoteFileSystemObject
      include Observable

      # @param [String] path Path to the object.
      # @param [Rosh::Host::Shells::Remote] remote_shell
      # @param [Symbol] force_type Make the object as a certain type.  +dir+,
      #   +file+, +link+.  Used when the object doesn't yet exist on the file
      #   system.
      # @return [Rosh::Host::RemoteDir,Rosh::Host::RemoteFile,Rosh::Host::RemoteLink]
      def self.create(path, remote_shell, force_type: nil)
        fso = new(path, remote_shell)

        if fso.directory?
          Rosh::Host::RemoteDir.new(path, remote_shell)
        elsif fso.file?
          Rosh::Host::RemoteFile.new(path, remote_shell)
        elsif fso.link?
          Rosh::Host::RemoteLink.new(path, remote_shell)
        elsif force_type
          klass = Rosh::Host.const_get("Remote#{force_type.capitalize}".to_sym)
          klass.new(path, remote_shell)
        end
      end

      attr_reader :path

      # @param [String] path Path to the remote file system object.
      # @param [Rosh::Host::Shells::Remote] remote_shell
      def initialize(path, remote_shell)
        @path = path
        @remote_shell = remote_shell
      end

      # Returns the pathname used to create file as a String. Does not normalize
      # the name.
      #
      # @return [String]
      def to_path
        @path
      end

      # @return [Boolean] +true+ if the object is a file; +false+ if not.
      def file?
        cmd = "[ -f #{@path} ]"
        @remote_shell.exec(cmd)

        @remote_shell.last_exit_status.zero?
      end

      # @return [Boolean] +true+ if the object is a directory; +false+ if not.
      def directory?
        cmd = "[ -d #{@path} ]"
        @remote_shell.exec(cmd)

        @remote_shell.last_exit_status.zero?
      end

      # @return [Boolean] +true+ if the object is a link; +false+ if not.
      def link?
        cmd = "[ -L #{@path} ]"
        @remote_shell.exec(cmd)

        @remote_shell.last_exit_status.zero?
      end

      # @return [Boolean] +true+ if the object exists on the file system;
      #   +false+ if not.
      def exists?
        cmd = "[ -e #{@path} ]"
        @remote_shell.exec(cmd)

        @remote_shell.last_exit_status.zero?
      end

      # @return [String] The owner of the file system object.
      def owner
        cmd = "ls -l #{@path} | awk '{print $3}'"

        @remote_shell.exec(cmd).strip
      end

      # Sets the file system object to +new_owner+.  If the update was a
      # success, the shell's #last_exit_status will be 0, which will be the case
      # even if the owner was set to the same owner.  If the update changes the
      # file system object, the observer's #update method gets called.
      #
      # @param [String] new_owner The user name to make the new owner of the file
      #   system object.
      def owner=(new_owner)
        old_owner = owner
        cmd = "chown #{new_owner} #{@path}"
        @remote_shell.exec(cmd)

        if @remote_shell.last_exit_status.zero? && old_owner != new_owner
          changed
          notify_observers(self, attribute: :owner, old: old_owner, new: new_owner)
        end
      end

      # @return [String] The group of the file system object.
      def group
        cmd = "ls -l #{@path} | awk '{print $4}'"

        @remote_shell.exec(cmd).strip
      end

      # Sets the group on the file system object to +new_group+.  If the update was a
      # success, the shell's #last_exit_status will be 0, which will be the case
      # even if the group was set to the same group.  If the update changes the
      # file system object, the observer's #update method gets called.
      #
      # @param [String] new_group The group name to make the new group of the file
      #   system object.
      def group=(new_group)
        old_group = group
        cmd = "chgrp #{new_group} #{@path}"
        @remote_shell.exec(cmd)

        if @remote_shell.last_exit_status.zero? && old_group != new_group
          changed
          notify_observers(self, attribute: :group, old: old_group, new: new_group)
        end
      end

      # @return [Integer] The mode of the file system object.
      def mode
        cmd = "ls -l #{@path} | awk '{print $1}'"
        letter_mode = @remote_shell.exec(cmd)
        %r[^(?<type>.)(?<user>.{3})(?<group>.{3})(?<others>.{3})] =~ letter_mode.strip

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

        if user && group && others
          number_mode = ''
          number_mode << converter.call(user)
          number_mode << converter.call(group)
          number_mode << converter.call(others)

          number_mode.to_i
        else
          nil
        end
      end

      # Sets the mode on the file system object to +new_mode+.  If the update was a
      # success, the shell's #last_exit_status will be 0, which will be the case
      # even if the mode was set to the same mode.  If the update changes the
      # file system object, the observer's #update method gets called.
      #
      # @param [Integer] new_mode The mode to set on the file
      #   system object.
      def mode=(new_mode)
        old_mode = mode
        cmd = "chmod #{new_mode} #{@path}"
        @remote_shell.exec(cmd)

        if @remote_shell.last_exit_status.zero? && old_mode != new_mode.to_i
          changed
          notify_observers(self, attribute: :mode, old: old_mode, new: new_mode)
        end
      end

      # Just like Ruby's File#basename, returns the base name of the object.
      #
      # @return [String]
      def basename
        File.basename(@path)
      end

      # Removes the file system object from the remote host.  If the removal was
      # successful, the shell's #last_exit_status will be 0, which will be the
      # case if the file didn't exist before making the call.  If the removal
      # actually removes the object, the observer's #update method gets called.
      def remove
        existed = exists?
        cmd = "rm -rf #{@path}"
        @remote_shell.exec(cmd)

        success = @remote_shell.last_exit_status.zero?

        if success && existed
          changed
          notify_observers(self, attribute: :path, old: @path, new: nil)
        end

        success
      end
    end
  end
end

require_relative 'remote_dir'
require_relative 'remote_file'
require_relative 'remote_link'
