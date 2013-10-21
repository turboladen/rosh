require_relative 'kernel_refinements'
require_relative 'changeable'
require_relative 'observer'
require_relative 'observable'
require_relative 'service_manager/service'


class Rosh
  class ServiceManager
    include Rosh::Changeable
    include Rosh::Observer
    include Rosh::Observable

    def initialize(host_name)
      @host_name = host_name
    end

    def [](name)
      result = Service.new(name, @host_name)
      result.add_observer(self)

      result
    end

    def installed_services
      adapter.installed_services
    end

    private

    def adapter
      return @adapter if @adapter

      @adapter = case current_host.operating_system
      when :darwin
        require_relative 'service_manager/manager_adapters/launch_ctl'
        ServiceManager::ManagerAdapters::LaunchCtl
      when :linux
        require_relative 'service_manager/manager_adapters/init'
        ServiceManager::ManagerAdapters::Init
      end

      @adapter.host_name = @host_name

      @adapter
    end
  end
end
