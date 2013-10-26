class Rosh
  module FunctionalExampleGroup
    def self.included(base)
      base.metadata[:type] = :functional
    end
  end
end
