class Rosh
  class ProcessManager
    module ObjectAdapters
      module Local
        def send_signal(sig)
          ::Process.kill(sig, @pid)
        end
      end
    end
  end
end
