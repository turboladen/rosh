class Rosh
  class CLI
    module Completion

      def self.build
        @commands, @hosts, @target = yield

        self
      end

      def self.call(string)
        case Readline.line_buffer
        when /^ch /
          @hosts
        else
          @commands | Dir["#{string}*"]
        end.grep(%r[^#{Regexp.escape(string)}])
      end
    end
  end
end

if Readline.respond_to?('basic_word_break_characters=')
  Readline.basic_word_break_characters= " \t\n`><=;|&{("
end

Readline.completion_append_character = nil
