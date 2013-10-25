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

    def supported_signals
      signal_adapter.list
    end

    private

    def process_adapter
      return @process_adapter if @process_adapter

      @process_adapter = if current_host.local?
        require_relative 'process_manager/manager_adapters/local'
        ProcessManager::ManagerAdapters::Local
      else
        require_relative 'process_manager/manager_adapters/remote'
        ProcessManager::ManagerAdapters::Remote
      end

      @process_adapter.host_name = @host_name

      @process_adapter
    end

    def signal_adapter
      return @signal_adapter if @signal_adapter

      @signal_adapter = if current_host.local?
        require_relative 'process_manager/manager_adapters/local_signal'
        ProcessManager::ManagerAdapters::LocalSignal
      else
        require_relative 'process_manager/manager_adapters/remote_signal'
        ProcessManager::ManagerAdapters::RemoteSignal
      end

      @signal_adapter.host_name = @host_name

      @signal_adapter
    end
  end
end
