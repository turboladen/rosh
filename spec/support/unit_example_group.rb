class Rosh
  module UnitExampleGroup
    def self.included(base)
      base.metadata[:type] = :unit
    end
  end
end
