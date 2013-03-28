class Rosh
  module BuiltinCommands
    class Pwd < Command
      DESCRIPTION = 'Displays the current working directory.'

      def initialize
        super(DESCRIPTION)
      end

      # @return [Hash{String => Rosh::File,Rosh::Directory}] Each file or directory in the
      #   given path.
      def execute
        [0, Dir.pwd]
      end
    end
  end
end
