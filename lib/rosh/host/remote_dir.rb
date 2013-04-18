require_relative 'remote_file_system_object'


class Rosh
  class Host
    class RemoteDir < RemoteFileSystemObject
      def owner
        cmd = "ls -ld #{@path} | awk '{print $3}'"

        @remote_shell.exec(cmd)
      end

      def group
        cmd = "ls -ld #{@path} | awk '{print $4}'"

        @remote_shell.exec(cmd)
      end

      def create
        cmd = "mkdir -p #{@path}"
        @remote_shell.exec(cmd)

        success = @remote_shell.last_exit_status.zero?

        if success
          changed
          notify_observers(:create, @path)
        end

        success
      end

      def mode
        cmd = "ls -ld #{@path} | awk '{print $1}'"
        letter_mode = @remote_shell.exec(cmd)
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
    end
  end
end
