require_relative '../service_types/launch_ctl'


class Rosh
  class Host
    module ServiceManagers
      class LaunchCTL
        def initialize(host_name)
          @host_name = host_name
        end

        def list
          result = current_shell.exec 'launchctl list'

          services = []
          result.each_line.each do |line|
            next if line =~ /^PID/

            line.match /(?<pid>\S+)\s+(?<status>\S+)\s+(?<name>[\S]+)/

            if $~
              pid = $~[:pid].to_i
            else
              puts "no match data for line:", line
            end

            services << create($~[:name], pid)
          end

          services
        end

        def [](name)
          create(name, nil)
        end

        private

        def create(name, pid)
          Rosh::Host::ServiceTypes::LaunchCTL.new(name, @host_name, pid)
        end
      end
    end
  end
end
