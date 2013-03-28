require_relative '../command'


class Rosh
  module BuiltinCommands
    class Cd < Command
      def initialize(path=Dir.home)
        @path = path == '..' ? '../' : path.strip
        description = "Changing current working directory to #{@path}"
        super(description)
      end

      def execute
        puts "path: #{@path}"

        begin
          Dir.chdir @path
          [0, Dir.pwd]
        rescue Errno::ENOENT => ex
          [1, ex]
        end
      end
    end
  end
end
