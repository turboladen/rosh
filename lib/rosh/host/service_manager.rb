require 'observer'
require_relative '../string_refinements'


class Rosh
  class Host
    class ServiceManager
      include Observable

      attr_writer :bin_path

      def initialize(host_name, manager_type)
        @host_name = host_name
        load_strategy(manager_type)
      end

      def [](service_name)
        create_service(service_name)
      end

      def bin_path
        warn 'Not implemented!  Implement in service type...'
      end

      def list
        warn 'Not implemented!  Implement in service type...'
      end

      private

      # Mixes in the +manager_type+'s methods.
      #
      # @param [Symbol, String] manager_type
      def load_strategy(manager_type)
        require_relative "service_managers/#{manager_type}"

        service_manager_klass =
          Rosh::Host::ServiceManagers.const_get(manager_type.to_s.classify)

        self.extend service_manager_klass
      end
    end
  end
end
