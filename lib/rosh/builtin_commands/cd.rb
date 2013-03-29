require_relative '../command'


class Rosh
  module BuiltinCommands
    class Cd < Command
      def initialize(path=Dir.home)
        @path = path == '..' ? '../' : path.strip
        description = "Changing current working directory to #{@path}"
        super(description)
      end

      def local_execute
        proc do
          puts "path: #{@path}"

          begin
            Dir.chdir @path
            ::Rosh::CommandResult.new(Dir.pwd, 0)
          rescue Errno::ENOENT => ex
            ::Rosh::CommandResult.new(ex, 1)
          end
        end
      end

      def remote_execute
        proc do |ssh|
          ssh.run "pwd #{@path}"
        end
      end
    end
  end
end
