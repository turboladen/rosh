require_relative 'command_result'


class Rosh
  class LocalShell

    def pwd
      ::Rosh::CommandResult.new(ENV['PWD'], 0)
    end
  end
end
