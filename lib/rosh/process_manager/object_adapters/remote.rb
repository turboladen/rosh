class Rosh
  class ProcessManager
    module ObjectAdapters
      module Remote
        def send_signal(sig)
          output = if sig.is_a? String
                     current_shell.exec_internal("kill -s #{sig} #{@pid}")
                   else
                     current_shell.exec_internal("kill -#{sig} #{@pid}")
          end

          return true if current_shell.last_exit_status.zero?

          if output.match /no such process/i
            fail Rosh::ProcessManager::ProcessNotFound, output
          end
        end
      end
    end
  end
end
