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
      def execute
        begin
          contents = open(@file).read
          [0, contents]
        rescue Errno::ENOENT, Errno::EISDIR => ex
          [1, ex]
        end
      end
    end
  end
end
