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
    host = Rosh.find_by_host_name(@host_name)

    unless host
      raise "No host found with name '#{@host_name}'"
    end

    host
  end

  def current_user
    current_host.user
  end

  def good_info(text)
    $stdout.puts "[#{current_user}@#{current_host.name}]>> #{text.strip}".light_blue
  end

  def bad_info(text)
    $stderr.puts "[#{current_user}@#{current_host.name}]!> #{text.strip}".light_red
  end

  def run_info(text)
    $stdout.puts "[#{current_user}@#{current_host.name}]<< #{text.strip}".yellow
  end

  def echo_rosh_command(*extra)
    unless internal_call?
      path, meth = caller_info(caller(1, 1))
      text = meth
      text << " #{extra.compact.map(&:strip).join(', ')}" unless extra.empty?

      $stdout.puts "[#{current_user}@#{current_host.name}:#{path}]> #{text}".bold
    end
  end

  def caller_info(backtrace)
    %r[rosh/lib/rosh/(?<path>[^\.]+).*`(?<meth>\S+)'] =~ backtrace.first

    [path, meth.upcase]
  end

  private

  def internal_call?
    result = caller(3, 1).first

    result.match %r[rosh/lib/rosh]
  end
end
