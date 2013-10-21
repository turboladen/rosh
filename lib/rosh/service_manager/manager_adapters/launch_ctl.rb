require_relative 'base'
require_relative '../service'


class Rosh
  class ServiceManager
    module ManagerAdapters
      class LaunchCtl
        include Base

        class << self
          def installed_services
            result = current_shell.exec 'launchctl list'

            services = []
            result.each_line.each do |line|
              next if line =~ /^PID/

              line.match /(?<pid>\S+)\s+(?<status>\S+)\s+(?<name>[\S]+)/

              if $~
                pid = $~[:pid].to_i
              else
                puts 'no match data for line:', line
              end

              services << Rosh::ServiceManager::Service.new($~[:name], @host_name)
            end

            services
          end
        end
      end
    end
  end
end
