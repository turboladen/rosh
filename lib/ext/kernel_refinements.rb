require 'colorize'
# require_relative 'shell/private_command_result'

# Methods for using throughout Rosh.
module RoshKernelAdditions
  def good_info(text)
    $stdout.puts "[#{Rosh.environment.current_user}@#{Rosh.environment.current_host.name}]>> #{text.strip}".light_blue
  end

  def bad_info(text)
    $stderr.puts "[#{Rosh.environment.current_user}@#{Rosh.environment.current_host.name}]!> #{text.strip}".light_red
  end

  def run_info(text)
    $stdout.puts "[#{Rosh.environment.current_user}@#{Rosh.environment.current_host.name}]<< #{text.strip}".yellow
  end

  def private_result(ruby_object, exit_status, as_string = nil)
    Rosh::Shell::PrivateCommandResult.new(ruby_object, exit_status, as_string)
  end

  def echo_rosh_command(*extra)
    if !internal_call?
      $stdout.puts(call_text(extra).bold)
    elsif internal_call? # && self.respond_to?(:log)
      log(call_text(extra).blue)
    end
  end

  def caller_info(backtrace)
    %r{rosh/lib/rosh/(?<path>[^\.]+).*`(?<meth>\S+)'} =~ backtrace.first

    [path, meth.upcase]
  end

  private

  def call_text(*extra)
    path, meth = caller_info(caller(2, 1))
    text = meth
    text << " #{extra.compact.map(&:to_s).map(&:strip).join(', ')}" unless extra.empty?

    "[#{Rosh.environment.current_user}@#{Rosh.environment.current_host.name}:#{path}]> #{text}"
  end

  # Is the last caller from a Rosh method?
  #
  # @return [Boolean]
  def internal_call?
    result = caller(3, 1).first

    result.match %r{rosh/lib/rosh}
  end
end

# Ruby's Kernel
module Kernel
  include RoshKernelAdditions
end
