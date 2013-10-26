class Rosh
  class FileSystem
    module ManagerAdapters
      module Base
        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          def host_name=(host_name)
            @host_name = host_name
          end
        end
      end
    end
  end
end
