require 'open-uri'
require_relative 'command_result'


class Rosh
  class LocalShell

    # Returns ruby_object as a String.
    def cat(file)
      file = file.strip

      begin
        contents = open(file).read
        ::Rosh::CommandResult.new(contents, 0)
      rescue Errno::ENOENT, Errno::EISDIR => ex
        ::Rosh::CommandResult.new(ex, 1)
      end
    end

    # Returns ruby_object as a String.
    def pwd
      ::Rosh::CommandResult.new(ENV['PWD'], 0)
    end
  end
end
