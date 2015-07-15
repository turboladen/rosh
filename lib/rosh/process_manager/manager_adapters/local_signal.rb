require_relative 'base_signal'

class Rosh
  class ProcessManager
    module ManagerAdapters
      class LocalSignal
        include BaseSignal

        class << self
          def list
            ::Signal.list
          end
        end
      end
    end
  end
end
