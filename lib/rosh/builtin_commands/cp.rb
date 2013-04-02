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

      def local_execute
        begin
          FileUtils.cp(@source, @destination)
          ::Rosh::CommandResult.new(true, 0)
        rescue Errno::ENOENT => ex
          ::Rosh::CommandResult.new(ex, 1)
        end
      end

      def remote_execute
        Rosh::Environment.current_host.ssh.run "cp #{@source} #{@destination}"
      end
    end
  end
end
