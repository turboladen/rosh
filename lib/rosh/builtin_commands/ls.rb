require_relative '../command'
require_relative '../directory'
require_relative '../file'


class Rosh
  module BuiltinCommands
    class Ls < Command
      DESCRIPTION = 'Lists files in the given directory.'

      def initialize(path=nil)
        super(DESCRIPTION)

        @path = path ? path.strip : nil
      end

      # @return [Hash{String => Rosh::File,Rosh::Directory}] Each file or directory in the
      #   given path.
      def local_execute
        proc do
          @path ||= Dir.pwd
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

            ::Rosh::CommandResult.new(r, 0)
          rescue Errno::ENOENT => ex
            r = { path => ex }
            ::Rosh::CommandResult.new(r, 1)
          end
        end
      end

      def remote_execute
        proc do |ssh|
          ssh.run "ls #{@path}"
        end
      end
    end
  end
end
