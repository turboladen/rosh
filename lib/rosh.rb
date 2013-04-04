require_relative 'rosh/host'


class Rosh
  attr_reader :hosts

  def initialize
    @hosts = {}
  end

  def add_host(hostname, host_alias=nil, **ssh_options)
    if host_alias.nil?
      @hosts[hostname] = Rosh::Host.new(hostname, ssh_options)
    else
      @hosts[host_alias] = Rosh::Host.new(hostname, ssh_options)
    end
  end
end
