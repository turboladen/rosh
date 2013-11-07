require_relative 'remote_base'


class Rosh
  class FileSystem
    module ObjectAdapters

      # Object representing a directory on a remote file system.
      module RemoteDir
        include RemoteBase

        # @return [Array<Rosh::FileSystem::*]
        def entries
          result = current_shell.exec_internal "ls #{@path}"

          return private_result([], 0) unless result

          if result.match %r[No such file or directory]
            ex = Rosh::ErrorENOENT.new(@path)
            return private_result(ex, 1)
          end

          actual_result = result.split.map do |entry|
            next if %w[. ..].include?(entry)
            full_path = @path == '/' ? "/#{entry}" : "#{@path}/#{entry}"

            Rosh::FileSystem.create(full_path, @host_name)
          end.compact

          private_result(actual_result, 0)
        end

        def open
          warn 'Not implemented!'
        end

        def mkdir
          current_shell.exec_internal "mkdir #{@path}"
          result = current_shell.last_exit_status.zero?
          exit_status = result ? 0 : 1

          private_result(result, exit_status)
        end

        def rmdir
          current_shell.exec_internal "rmdir #{@path}"
          result = current_shell.last_exit_status.zero?
          exit_status = result ? 0 : 1

          private_result(result, exit_status)
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
