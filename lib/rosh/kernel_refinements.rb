module Kernel

  # Returns the Rosh::Host::Shells::* shell based on the host label.
  #
  # @return [Rosh::Host::Shells::*]
  def current_shell
    host = Rosh.hosts[@host_label]

    unless host
      raise "No host found with label '#{@host_label}'"
    end

    host.shell
  end
end
