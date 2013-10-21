require_relative 'base'
require_relative '../service'


class Rosh
  class ServiceManager
    module ManagerAdapters
      class Init
        include Base

        class << self
          def installed_services
            case current_host.operating_system
            when :linux then linux_list
            when :freebsd then freebsd_list
            end
          end

          private

          def linux_list
            result = current_shell.ls '/etc/init.d'

            result.map do |file|
              Rosh::ServiceManager::Service.new(file.basename, @host_name)
            end
          end

          def freebsd_list
            result = current_shell.ls '/etc/rc.d'

            result.map do |file|
              Rosh::ServiceManager::Service.new(file.basename, @host_name)
            end
          end
        end
      end
    end
  end
end
