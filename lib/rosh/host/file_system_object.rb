require 'tempfile'


class Rosh
  class Host
    class FileSystemObject
      attr_reader :path

      def initialize(path, ssh, &result_block)
        @path = path
        @ssh = ssh
        @result_block = result_block
      end

      def file?
        cmd = "[ -f #{@path} ]"
        result = @ssh.run(cmd)
        @result_block.call(result)

        result.ssh_result.exit_code.zero?
      end

      def directory?
        cmd = "[ -d #{@path} ]"
        result = @ssh.run(cmd)
        @result_block.call(result)

        result.ssh_result.exit_code.zero?
      end

      def link?
        cmd = "[ -L #{@path} ]"
        result = @ssh.run(cmd)
        @result_block.call(result)

        result.ssh_result.exit_code.zero?
      end

      def exists?
        cmd = "[ -e #{@path} ]"
        result = @ssh.run(cmd)
        @result_block.call(result)

        result.ssh_result.exit_code.zero?
      end

      def read
        cmd = "cat #{@path}"
        result = @ssh.run(cmd)
        @result_block.call(result)

        result.ssh_result.stdout
      end

      def write(new_content)
        source_file = Tempfile.new('screenplay_fso')
        source_file.write(new_content)
        source_file.rewind

        result = @ssh.upload(source_file.path, @path)

        @result_block.call(result)
        result.ssh_result.stderr.empty?
      ensure
        source_file.close
        source_file.unlink
      end

      def owner
        cmd = "ls -l #{@path} | awk '{print $3}'"
        result = @ssh.run(cmd)
        @result_block.call(result.ssh_result)

        result.ssh_result.stdout.strip
      end

      def owner=(new_owner, sudo: false)
        cmd = "chown #{new_owner} #{@path}"
        cmd.insert(0, 'sudo ') if sudo
        result = @ssh.run(cmd)
        @result_block.call(result.ssh_result)

        result.ssh_result.exit_code.zero?
      end

      def group
        cmd = "ls -l #{@path} | awk '{print $4}'"
        result = @ssh.run(cmd)
        @result_block.call(result)

        result.ssh_result.stdout.strip
      end
    end
  end
end
