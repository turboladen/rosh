require_relative '../service'


class Rosh
  class Host
    module ServiceManagers
      module Init
        def initialize(host_name)
          @host_name = host_name
        end

        def list
          case current_host.operating_system
          when :linux then linux_list
          when :freebsd then freebsd_list
          end
        end

        private

        def create_service(name)
          Rosh::Host::Service.new(:init, name, @host_name)
        end

        def linux_list
          result = current_shell.ls '/etc/init.d'

          result.map { |file| create_service(file.basename) }
        end

        def freebsd_list
          result = current_shell.ls '/etc/rc.d'

          result.map { |file| create_service(file.basename) }
        end
      end
    end
  end
end
