class Rosh
  class ProcessManager
    module ManagerAdapters
      module Base
        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          def host_name=(host_name)
            @host_name = host_name
          end

          def supported_signals
            result = current_shell.exec 'kill -l'

            result.split(/\s+/).map do |signal|
              next if signal.match /\A\d/ or signal.empty?
              signal
            end.compact
          end
        end
      end
    end
  end
end
