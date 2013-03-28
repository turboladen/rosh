require_relative '../command'
require_relative '../directory'
require_relative '../file'


class Rosh
  module BuiltinCommands
    class Ls < Command
      DESCRIPTION = 'Lists files in the given directory.'

      def initialize(path=Dir.pwd)
        super(DESCRIPTION)

        @path = path.strip
      end

      # @return [Hash{String => Rosh::File,Rosh::Directory}] Each file or directory in the
      #   given path.
      def execute
        status = 0
        r = {}

        begin
          Dir.entries(@path).each do |entry|
            new_entry = if ::File.directory? "#{@path}/#{entry}"
              Rosh::Directory.new "#{@path}/#{entry}"
            elsif ::File.file? "#{@path}/#{entry}"
              Rosh::File.new "#{@path}/#{entry}"
            end

            r[entry] = new_entry
          end
        rescue Errno::ENOENT => ex
          status = 1
          r = { path => ex }
        end

        [status, r]
      end
    end
  end
end
