require_relative '../service_types/init'


class Rosh
  class Host
    module ServiceManagers
      class Init
        def initialize(shell, os_type)
          @shell = shell
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
          Rosh::Host::ServiceTypes::Init.new(name, @shell, @os_type)
        end

        def linux_list
          result = @shell.ls '/etc/init.d'

          services = result.ruby_object.map do |file|
            create(file.basename)
          end

          Rosh::CommandResult.new(services, 0, result.ssh_result)
        end

        def freebsd_list
          result = @shell.ls '/etc/rc.d'

          services = result.ruby_object.map do |file|
            create(file.basename)
          end

          Rosh::CommandResult.new(services, 0, result.ssh_result)
        end
      end
    end
  end
end
