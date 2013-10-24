require_relative 'kernel_refinements'
require_relative 'observable'
require_relative 'observer'
require_relative 'changeable'
#require_relative 'process_manager/process'


class Rosh
  class ProcessManager
    include Rosh::Changeable
    include Rosh::Observer
    include Rosh::Observable

    def initialize(host_name)
      @host_name = host_name
    end

    def [](name)
      result = Rosh::ProcessManager::Process.new(name, @host_name)
      result.add_observer(self)

      result
    end

    def list(name: nil, pid: nil)
      adapter.list_running(name, pid)
    end

    private

    def adapter
      return @adapter if @adapter

      @adapter = if current_host.local?
        require_relative 'process_manager/manager_adapters/local'
        ProcessManager::ManagerAdapters::Local
      else
        require_relative 'process_manager/manager_adapters/remote'
        ProcessManager::ManagerAdapters::Remote
      end

      @adapter.host_name = @host_name

      @adapter
    end
  end
end
