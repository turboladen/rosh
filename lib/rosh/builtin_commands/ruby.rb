require_relative '../command'


class Rosh
  module BuiltinCommands
    class Ruby < Command

      # @params [String] file The filename.
      def initialize(code, binding)
        @code = code.strip
        @binding = binding

        description = 'Executes some Ruby code'
        super(description)
      end

      # @return [String] The file contents.
      def local_execute
        proc do
          status = 0

          result = begin
            @code.gsub!(/puts/, '$stdout.puts')
            @binding.eval(@code)
          rescue => ex
            status = 1
            ex
          end

          ::Rosh::CommandResult.new(result, status)
        end
      end

      def remote_execute
        proc do |ssh|
          #ssh.run "cat #{@file}"
          warn 'Not implemented yet.'
        end
      end
    end
  end
end
