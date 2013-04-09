require_relative 'service'
Dir[File.dirname(__FILE__) + '/service_types/*.rb'].each(&method(:require))


class Rosh
  class Host
    class ServiceManager
      def initialize(host)
        @host = host
      end

      def [](service_name)
        case @host.operating_system
        when :darwin
          Rosh::Host::ServiceTypes::LaunchCTL.new(service_name, @host)
        when :linux
          Rosh::Host::ServiceTypes::Init.new(service_name, @host)
        end
      end
    end
  end
end
