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

          def su_user_name
            @su_user_name ||= current_user
          end

          def su_user_name=(new_user_name)
            @su_user_name = new_user_name
          end
        end
      end
    end
  end
end
