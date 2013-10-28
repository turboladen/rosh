require_relative 'kernel_refinements'
require_relative 'changeable'
require_relative 'observer'
require_relative 'observable'
require_relative 'service_manager/service'
require_relative 'service_manager/manager_adapter'


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

    def list
      adapter.list_services
    end

    private

    def adapter
      return @adapter if @adapter

      type = case current_host.operating_system
      when :darwin
        :launch_ctl
      when :linux
        :init
      end

      @adapter = ServiceManager::ManagerAdapter.new(type, @host_name)
    end
  end
end
