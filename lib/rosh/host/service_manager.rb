require_relative 'service'


class Rosh
  class Host
    class ServiceManager
      def initialize(host)
        @host = host
      end

      def [](service_name)
        Rosh::Host::Service.new(service_name, @host)
      end
    end
  end
end
