require_relative 'base_signal'

class Rosh
  class ProcessManager
    module ManagerAdapters
      class RemoteSignal
        include BaseSignal

        class << self
          def list
            output = current_shell.exec_internal 'kill -l'
            signal_list = {}

            output.split(/\s/).inject([]) do |result, signal|
              if signal.match /\A\d+/
                result << [$LAST_MATCH_INFO.to_s.to_i]
              elsif signal.match /\A\S+/
                result.last.unshift $LAST_MATCH_INFO.to_s
                key, value = result.pop
                signal_list[key.sub('SIG', '')] = value
              end

              result
            end

            signal_list
          end
        end
      end
    end
  end
end
