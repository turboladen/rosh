require 'fileutils'
require_relative '../command'


class Rosh
  module BuiltinCommands
    class Cp < Command
      def initialize(source, destination)
        @source = source.strip
        @destination = destination.strip

        description = "Copy #{@source} to #{@destination}"
        super(description)
      end

      def execute
        begin
          FileUtils.cp(@source, @destination)
          [0, true]
        rescue Errno::ENOENT => ex
          [1, ex]
        end
      end
    end
  end
end
