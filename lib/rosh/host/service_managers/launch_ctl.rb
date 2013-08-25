require_relative '../service'


class Rosh
  class Host
    module ServiceManagers
      module LaunchCtl
        def list
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

            services << create_service($~[:name], pid)
          end

          services
        end

        private

        def create_service(name, pid)
          Rosh::Host::Service.new(:launch_ctl, name, @host_name, pid: pid)
        end
      end
    end
  end
end
