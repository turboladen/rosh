require_relative 'service_manager/service'
require_relative 'service_manager/manager_adapter'

class Rosh
  class ServiceManager
    def initialize(host_name)
      @host_name = host_name
    end

    def [](name)
      result = Service.new(name, @host_name)
      result.add_observer(self)

      result
    end

    def list
      echo_rosh_command

      adapter.list_services
    end

    private

    def adapter
      return @adapter if @adapter

      type = case current_host.operating_system
             when :darwin then :launch_ctl
             when :linux then :init
             end

      @adapter = ServiceManager::ManagerAdapter.new(type, @host_name)
    end
  end
end
