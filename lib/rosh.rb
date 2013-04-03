require_relative 'rosh/host'


class Rosh
  attr_reader :hosts

  def initialize
    @hosts = {}
  end

  def add_host(hostname, **ssh_options)
    @hosts[hostname] = Rosh::Host.new(hostname, ssh_options)
  end
end
