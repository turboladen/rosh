class Rosh
  module BuiltinCommands
    class History < Command
      DESCRIPTION = 'Shows a list of all commands that have been executed.'

      def initialize
        super(DESCRIPTION)
      end

      def execute
        lines = []

        Readline::HISTORY.to_a.each_with_index do |cmd, i|
          lines << "  #{i}  #{cmd}"
        end

        [0, lines]
      end
    end
  end
end

