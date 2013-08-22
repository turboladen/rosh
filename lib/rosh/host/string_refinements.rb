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
    #self.snake_case.to_sym
    self.gsub(' ', '_').gsub('.', '').gsub('-', '_').downcase.to_sym
  end

  def camel_case
    split('_').map{ |e| e.capitalize }.join
  end

  def classify
    camel_case.to_sym
  end

  def snake_case
    self.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr('-', '_').
      downcase
  end
end
