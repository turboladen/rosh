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
        puts "path: #{@path}"

        begin
          Dir.chdir @path
          ::Rosh::CommandResult.new(Dir.pwd, 0)
        rescue Errno::ENOENT => ex
          ::Rosh::CommandResult.new(ex, 1)
        end
      end

      def remote_execute
        Rosh::Environment.current_host.ssh.run "cd #{@path}"
      end
    end
  end
end
