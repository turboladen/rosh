require 'yaml'
require_relative 'rosh/host'


class Rosh
  attr_reader :hosts

  DEFAULT_RC_FILE = '.roshrc.yml'

  def initialize
    @hosts = {}
    @config = nil
  end

  def add_host(hostname, host_alias: nil, throw_on_fail: true, **ssh_options)
    if host_alias.nil?
      @hosts[hostname] = Rosh::Host.new(hostname, throw_on_fail, ssh_options)
    else
      @hosts[host_alias] = Rosh::Host.new(hostname, throw_on_fail, ssh_options)
    end
  end

  def config
    return @config if @config

    if File.exists? DEFAULT_RC_FILE
      erb = ERB.new(File.read(DEFAULT_RC_FILE))
      @config = YAML.load(erb.result)
    end
  end
end
