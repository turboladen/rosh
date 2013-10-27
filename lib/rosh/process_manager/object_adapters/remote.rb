class Rosh
  class ProcessManager
    module ObjectAdapters
      module Remote
        def send_signal(sig)
          output = if sig.kind_of? String
            current_shell.exec("kill -s #{sig} #{@pid}")
          else
            current_shell.exec("kill -#{sig} #{@pid}")
          end

          return true if current_shell.last_exit_status.zero?

          if output.match /no such process/i
            raise Rosh::ProcessManager::ProcessNotFound, output
          end
        end
      end
    end
  end
end
