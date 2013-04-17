require 'shellwords'
require 'highline/import'
require 'log_switch'
require 'colorize'

require_relative '../../command_result'
require_relative '../../errors'


class Rosh
  class Host
    module Shells

      class Base
        extend LogSwitch
        include LogSwitch::Mixin

        attr_reader :history

        def initialize
          @history = []
        end

        # The shell's environment.  Note this doesn't trump the Ruby process's ENV
        # settings (which are still accessible).
        #
        # @return [Hash] A Hash containing the environment info.
=begin
        def env
          log 'env called'

          process(:env) do
            @path ||= ENV['PATH'].split(':')

            env = {
              path: @path,
              shell: File.expand_path(File.basename($0), File.dirname($0)),
              pwd: pwd.to_path
            }

            [env, 0]
          end
        end
=end

        # @param [Integer] status Exit status code.
        def exit(status=0)
          Kernel.exit(status)
        end

        def last_result
          @history.last[:output]
        end
        alias :__ :last_result

        # @return [Integer] Shortcut to the result of the last command executed.
        def last_exit_status
          @history.last[:exit_status]
        end
        alias :_? :last_exit_status

        # @return The last exception that was raised.
        def last_exception
          @history.reverse.find { |result| result[:output].kind_of? Exception }
        end
        alias :_! :last_exception

        private

        # Saves the result of the block given to #last_result and exit code to
        # #last_exit_status.
        #
        # @param [Array<String>, String] args Arguments given to the method.
        #
        # @return The result of the block that was given.
        def process(cmd, **args, &block)
          result, exit_status, ssh_output = block.call

          @history << {
            command: cmd,
            arguments: args,
            output: result,
            exit_status: exit_status,
            ssh_output: ssh_output
          }

          @history.last[:output]
        end
      end
    end
  end
end
