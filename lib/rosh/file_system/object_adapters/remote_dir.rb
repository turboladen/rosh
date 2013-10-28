require_relative 'remote_base'


class Rosh
  class FileSystem
    module ObjectAdapters

      # Object representing a directory on a remote file system.
      module RemoteDir
        include RemoteBase

        def entries
          current_shell.ls(@path)
        end

        def open
          warn 'Not implemented!'
        end

        def mkdir
          current_shell.exec "mkdir #{@path}"

          current_shell.last_exit_status.zero?
        end

        def rmdir
          current_shell.exec "rmdir #{@path}"

          current_shell.last_exit_status.zero?
        end
      end

=begin
        # @return [String] The owner of the remote directory.
        def owner
          cmd = "ls -ld #{@path} | awk '{print $3}'"

          current_shell.exec(cmd).strip
        end

        # @return [String] The group of the remote directory.
        def group
          cmd = "ls -ld #{@path} | awk '{print $4}'"

          current_shell.exec(cmd).strip
        end

        # @return [Integer] The mode of the file system object.
        def mode
          cmd = "ls -ld #{@path} | awk '{print $1}'"
          letter_mode = current_shell.exec(cmd)

          mode_to_i(letter_mode)
        end

        # Creates the directory if it doesn't already exist.  Notifies observers
        # with the new path.
        #
        # @return [Boolean] +true+ if the directory already exists or if creating
        #   it was successful; +false+ if creating it failed.
        def save
          return true if exists?

          cmd = "mkdir -p #{@path}"
          current_shell.exec(cmd)

          success = current_shell.last_exit_status.zero?

          if success
            changed
            notify_observers(self,
              attribute: :path, old: nil, new: @path,
              as_sudo: current_shell.su?)
          end

          success
        end
=end
    end
  end
end
