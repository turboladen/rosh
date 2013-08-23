module Kernel

  # Returns the Rosh::Host::Shells::* shell based on the host label.
  #
  # @return [Rosh::Host::Shells::*]
  def current_shell
    current_host.shell
  end

  def current_host
    host = Rosh.find_by_hostname @host_name

    unless host
      raise "No host found with name '#{@host_name}'"
    end

    host
  end
end
