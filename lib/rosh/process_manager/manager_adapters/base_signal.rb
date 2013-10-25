class Rosh
  class ProcessManager
    module ManagerAdapters
      module BaseSignal
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
