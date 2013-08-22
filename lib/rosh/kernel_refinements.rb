module Kernel
  def current_shell
    Rosh.hosts[@host_label].shell
  end

  def current_shell=(shell)
    Rosh.hosts[@host_label].shell = shell
  end
end
