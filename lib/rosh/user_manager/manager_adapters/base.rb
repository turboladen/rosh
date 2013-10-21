class Rosh
  class UserManager
    module ManagerAdapters
      module Base
        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          def host_name=(host_name)
            @host_name = host_name
          end

          def open_directory?
            current_host.darwin?
          end
        end
      end
    end
  end
end
