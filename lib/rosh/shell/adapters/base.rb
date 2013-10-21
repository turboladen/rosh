class Rosh
  class Shell
    module Adapters
      module Base
        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          def host_name=(host_name)
            @host_name = host_name
          end

          def sudo
            @sudo ||= false
          end

          def sudo=(new_value)
            @sudo = new_value
          end
        end
      end
    end
  end
end
