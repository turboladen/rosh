require_relative '../changeable'
require_relative '../observable'
require_relative 'object_adapter'


class Rosh
  class ServiceManager
    class ServiceNotFound < RuntimeError; end

    class Service
      include Rosh::Changeable
      include Rosh::Observable

      def initialize(service_name, host_name)
        @service_name = service_name
        @host_name = host_name
      end

      def exists?
        adapter.exists?
      end

      def info
        adapter.info
      end

      def name
        @service_name
      end

      def start
        current_status = self.status

        change_if(current_status != :running) do
          adapter.start

          notify_about(self, :status, from: current_status, to: :running) do
            adapter.status == :running
          end
        end
      end

      def start!
        current_status = self.status

        change_if(current_status != :running) do
          adapter.start!

          notify_about(self, :status, from: current_status, to: :running) do
            adapter.status == :running
          end
        end
      end

      def start_at_boot!
        adapter.start_at_boot!
      end

      def running?
        self.status == :running
      end
      alias_method :started?, :running?

      def stop
        current_status = self.status

        change_if(current_status != :stopped) do
          adapter.stop

          notify_about(self, :status, from: current_status, to: :stopped) do
            adapter.status == :stopped
          end
        end
      end

      def stop!
        current_status = self.status

        change_if(current_status != :stopped) do
          adapter.stop!

          notify_about(self, :status, from: current_status, to: :stopped) do
            adapter.status == :stopped
          end
        end
      end

      def stopped?
        self.status == :stopped
      end

      def status
        adapter.status
      end

      private

      def adapter
        return @adapter if @adapter

=begin
        @adapter = case current_host.operating_system
        when :darwin
          require_relative 'object_adapters/launch_ctl'
          ServiceManager::ObjectAdapters::LaunchCtl
        when :linux, :freebsd
          require_relative 'object_adapters/init'
          ServiceManager::ObjectAdapters::Init
        end

        @adapter.service_name = @name
        @adapter.host_name = @host_name
=end
        type = case current_host.operating_system
        when :darwin
          :launch_ctl
        else
          :init
        end

        @adapter = ServiceManager::ObjectAdapter.new(@service_name, type, @host_name)
      end
    end
  end
end
