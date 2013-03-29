require 'colorize'
#require_relative 'logger'
require_relative 'command_result'


class Rosh
  class Command
    #include LogSwitch::Mixin

    attr_reader :description
    attr_reader :fail_block

    def initialize(description)
      @description = description

      @fail_block = nil
      @on_fail ||= nil

      #log "description: #{@description}"
      puts "description: #{@description}"
    end

    def execute(context=:local)
      if context == :local
        local_execute
      else
        remote_execute
      end
    end

    def local_execute
      warn 'Implement in child'
    end

    def remote_execute
      warn 'Implement in child'
    end

    def handle_on_fail
      if @on_fail
        puts 'Command failed; setting up to run failure block...'.yellow
        @fail_block = @on_fail
      end
    end
  end
end
