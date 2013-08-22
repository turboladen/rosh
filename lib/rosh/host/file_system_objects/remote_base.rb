require 'observer'


class Rosh
  class Host
    module FileSystemObjects

      # This is a generic base class for representing file system objects: files,
      # directories, and links.  It implements what's pretty close to Ruby's
      # +File+ class.
      #
      # Objects of this type are Observable and will notify observers with:
      # self, attribute: [changed attribute], old: [old value], new: [new value]
      #
      # When serializing (i.e. dumping to YAML), it maintains only the path to the
      # object.
      class RemoteBase
        include Observable

        # @param [String] path Path to the object.
        # @param [String,Symbol] host_label
        # @return [Rosh::Host::FileSystemObjects::RemoteDir,Rosh::Host::FileSystemObjects::RemoteFile,Rosh::Host::FileSystemObjects::RemoteLink]
        def self.create(path, host_label)
          fso = new(path, host_label)

          if fso.directory?
            Rosh::Host::FileSystemObjects::RemoteDir.new(path, host_label)
          elsif fso.file?
            Rosh::Host::FileSystemObjects::RemoteFile.new(path, host_label)
          elsif fso.link?
            Rosh::Host::FileSystemObjects::RemoteLink.new(path, host_label)
          end
        end

        attr_reader :path

        # @param [String] path Path to the remote file system object.
        # @param [String,Symbol] host_label
        def initialize(path, host_label)
          @path = path.strip
          @host_label = host_label
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
          current_shell.exec(cmd)

          current_shell.last_exit_status.zero?
        end

        # @return [Boolean] +true+ if the object is a directory; +false+ if not.
        def directory?
          cmd = "[ -d #{@path} ]"
          current_shell.exec(cmd)

          current_shell.last_exit_status.zero?
        end

        # @return [Boolean] +true+ if the object is a link; +false+ if not.
        def link?
          cmd = "[ -L #{@path} ]"
          current_shell.exec(cmd)

          current_shell.last_exit_status.zero?
        end

        # @return [Boolean] +true+ if the object exists on the file system;
        #   +false+ if not.
        def exists?
          cmd = "[ -e #{@path} ]"
          current_shell.exec(cmd)

          current_shell.last_exit_status.zero?
        end

        # @return [String] The owner of the file system object.
        def owner
          cmd = "ls -l #{@path} | awk '{print $3}'"

          current_shell.exec(cmd).strip
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
          return if current_shell.check_state_first? && old_owner == new_owner

          cmd = "chown #{new_owner} #{@path}"
          current_shell.exec(cmd)

          if current_shell.last_exit_status.zero? && old_owner != new_owner
            changed
            notify_observers(self,
              attribute: :owner, old: old_owner, new: new_owner,
              as_sudo: current_shell.su?)
          end
        end

        # @return [String] The group of the file system object.
        def group
          cmd = "ls -l #{@path} | awk '{print $4}'"

          current_shell.exec(cmd).strip
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
          return if current_shell.check_state_first? && old_group == new_group

          cmd = "chgrp #{new_group} #{@path}"
          current_shell.exec(cmd)

          if current_shell.last_exit_status.zero? && old_group != new_group
            changed
            notify_observers(self,
              attribute: :group, old: old_group, new: new_group,
              as_sudo: current_shell.su?)
          end
        end

        # @return [Integer] The mode of the file system object.
        def mode
          cmd = "ls -l #{@path} | awk '{print $1}'"
          letter_mode = current_shell.exec(cmd)

          mode_to_i(letter_mode)
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
          return if current_shell.check_state_first? && old_mode == new_mode

          cmd = "chmod #{new_mode} #{@path}"
          current_shell.exec(cmd)

          if current_shell.last_exit_status.zero? && old_mode != new_mode.to_i
            changed
            notify_observers(self,
              attribute: :mode, old: old_mode, new: new_mode,
              as_sudo: current_shell.su?)
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
          return if current_shell.check_state_first? && !existed

          cmd = "rm -rf #{@path}"
          current_shell.exec(cmd)

          success = current_shell.last_exit_status.zero?

          if success && existed
            changed
            notify_observers(self,
              attribute: :path, old: @path, new: nil,
              as_sudo: current_shell.su?)
          end

          success
        end

        # Called by serializer when dumping.
        def encode_with(coder)
          coder['path'] = @path
          coder['host_label'] = @host_label
        end

        # Called by serializer when loading.
        def init_with(coder)
          @path = coder['path']
          @host_label = coder['host_label']
        end

        #-------------------------------------------------------------------------
        # Privates
        #-------------------------------------------------------------------------
        private

        # Converts mode as letters ('-rwxr--r--') to numbers (744).  Returns +nil+
        # if it can't determine numbers from +letter_mode+.
        #
        # @param [String] letter_mode
        # @return [Integer]
        def mode_to_i(letter_mode)
          %r[^(?<type>.)(?<user>.{3})(?<group>.{3})(?<others>.{3})] =~ letter_mode.strip

          converter = lambda do |letters|
            value = 0

            letters.chars do |char|
              case char
              when '-' then
                next
              when 'x' then
                value += 1
              when 'w' then
                value += 2
              when 'r' then
                value += 4
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
      end
    end
  end
end

require_relative 'remote_dir'
require_relative 'remote_file'
require_relative 'remote_link'
