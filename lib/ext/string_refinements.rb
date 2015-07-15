# class Rosh
#   module StringRefinements
#     refine String do
#       def to_safe_down_sym
#         self.gsub(' ', '_').gsub('.', '').gsub('-', '_').downcase.to_sym
#       end
#     end
#   end
# end

# Some helper methods for Strings.
module RoshStringRefinements
  # Substitutes spaces and dashes for underscores and removes periods.
  #
  # @return [String]
  def rosh_safe
    tr(' -', '_').tr('.', '')
  end

  # Make a Symbol from the String, substituting spaces and dashes for
  # underscores and removing periods.
  #
  # @return [String]
  def to_safe_down_sym
    rosh_safe.downcase.to_sym
  end

  # Turns the string into a CamelCase string.
  #
  # @return [String]
  def camel_case
    split('_').map(&:capitalize).join
  end

  # A CamelCased Symbol.
  #
  # @return [Symbol]
  def classify
    camel_case.to_sym
  end

  # Turns 'Rosh::FileSystem::File' into 'rosh.file_system.file'
  #
  # @return [String]
  def declassify(separator = '.')
    snake_case.split('/').join(separator)
  end

  # @return [String]
  def snake_case
    gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
      gsub(/([a-z\d])([A-Z])/, '\1_\2').
      tr('-', '_').
      downcase
  end
end

# Ruby's String
class String
  include RoshStringRefinements
end
