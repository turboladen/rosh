require_relative '../service_types/init'


class Rosh
  class Host
    module ServiceManagers
      class Init
        def initialize(os_type, host_name)
          @host_name = host_name
          @os_type = os_type
        end

        def list
          case @os_type
          when :linux then linux_list
          when :freebsd then freebsd_list
          end
        end

        def [](name)
          create(name)
        end

        private

        def create(name)
          Rosh::Host::ServiceTypes::Init.new(name, @os_type, @host_name)
        end

        def linux_list
          result = current_shell.ls '/etc/init.d'

          result.map { |file| create(file.basename) }
        end

        def freebsd_list
          result = current_shell.ls '/etc/rc.d'

          result.map { |file| create(file.basename) }
        end
      end
    end
  end
end
