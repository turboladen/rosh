class Rosh
  module HostMethods
    # @return [Rosh::Host]
    def host(host_name = nil)
      host_name ||= @host_name
      Rosh.environment.find_by_host_name(host_name)
    end
  end
end
