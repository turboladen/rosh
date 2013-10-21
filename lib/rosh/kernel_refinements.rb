require 'colorize'
require_relative '../rosh'


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
    host = Rosh.find_by_host_name(@host_name) || Rosh.add_host(@host_name)

    unless host
      raise "No host found with name '#{@host_name}'"
    end

    host
  end

  def good_info(text)
    h = @host_name || 'localhost'
    $stdout.puts "[#{h}] => #{text.strip}".light_blue
  end

  def bad_info(text)
    h = @host_name || 'localhost'
    $stderr.puts "[#{h}] !> #{text.strip}".light_red
  end

  def run_info(text)
    h = @host_name || 'localhost'
    $stdout.puts "[#{h}] $$ #{text.strip}".yellow
  end
end
