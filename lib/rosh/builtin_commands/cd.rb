require_relative '../command'


class Rosh
  module BuiltinCommands
    class Cd < Command
      def initialize(path)
        @path = path == '..' ? '../' : path.strip
        description = "Changing current working directory to #{@path}"
        super(description)
      end

      def local_execute
        path = ::File.expand_path @path

        begin
          Dir.chdir ::File.expand_path(path)
          ::Rosh::CommandResult.new(path, 0)
        rescue Errno::ENOENT => ex
          ::Rosh::CommandResult.new(ex, 1)
        end
      end

      def remote_execute
        result = Rosh::Environment.current_host.ssh.run "cd #{@path} && pwd"

        if result.exit_status.zero?
          Rosh::CommandResult.new(result.ssh_result.stdout, 0)
        end
      end
    end
  end
end
