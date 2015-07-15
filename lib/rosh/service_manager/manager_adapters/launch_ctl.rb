require_relative '../service'

class Rosh
  class ServiceManager
    module ManagerAdapters
      module LaunchCtl
        def list_services
          result = current_shell.exec_internal 'launchctl list'

          services = []
          result.each_line.each do |line|
            next if line =~ /^PID/

            line.match /(?<pid>\S+)\s+(?<status>\S+)\s+(?<name>[\S]+)/

            if $LAST_MATCH_INFO
              pid = $LAST_MATCH_INFO[:pid].to_i
            else
              puts 'no match data for line:', line
            end

            services << Rosh::ServiceManager::Service.new($LAST_MATCH_INFO[:name], @host_name)
          end

          services
        end
      end
    end
  end
end
