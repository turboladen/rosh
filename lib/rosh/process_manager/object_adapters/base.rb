class Rosh
  class ProcessManager
    module ObjectAdapters
      module Base
        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          def pid=(pid)
            @pid = pid
          end

          def host_name=(host_name)
            @host_name = host_name
          end
        end
      end
    end
  end
end
