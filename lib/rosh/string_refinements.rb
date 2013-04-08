=begin
class Rosh
  module StringRefinements
    refine String do
      def to_safe_down_sym
        self.gsub(' ', '_').gsub('.', '').gsub('-', '_').downcase.to_sym
      end
    end
  end
end
=end

class String
  def to_safe_down_sym
    self.gsub(' ', '_').gsub('.', '').gsub('-', '_').downcase.to_sym
  end
end
