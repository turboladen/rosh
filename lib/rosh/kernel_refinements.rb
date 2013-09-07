module Kernel

  # Returns the Rosh::Host::Shells::* shell based on the host name.
  #
  # @return [Rosh::Host::Shells::*]
  def current_shell
    current_host.shell
  end

  # Returns the Rosh::Host base on the current @host_name.
  #
  # @return [Rosh::Host]
  def current_host
    host = Rosh.find_by_host_name @host_name

    unless host
      raise "No host found with name '#{@host_name}'"
    end

    host
  end
end
