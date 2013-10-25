require_relative 'base'


class Rosh
  class ProcessManager
    module ObjectAdapters
      class Local
        include Base

        class << self
          def send_signal(sig)
            ::Process.kill(sig, @pid)
          end
        end
      end
    end
  end
end
