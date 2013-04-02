require 'open-uri'
require_relative '../command'


class Rosh
  module BuiltinCommands
    class Cat < Command

      # @params [String] file The filename.
      def initialize(file)
        @file = file.strip

        description = "Displays the contents of file '#{@file}'."
        super(description)
      end

      # @return [String] The file contents.
      def local_execute
        begin
          contents = open(@file).read
          ::Rosh::CommandResult.new(contents, 0)
        rescue Errno::ENOENT, Errno::EISDIR => ex
          ::Rosh::CommandResult.new(ex, 1)
        end
      end

      def remote_execute
        Rosh::Environment.current_host.ssh.run "cat #{@file}"
      end
    end
  end
end
