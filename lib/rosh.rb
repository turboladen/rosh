require 'yaml'
require_relative 'rosh/host'


class Rosh
  DEFAULT_RC_FILE = '.roshrc.yml'
  @hosts = {}
  @config = nil

  def self.add_host(hostname, host_alias: nil, **ssh_options)
    if host_alias.nil?
      @hosts[hostname] = Rosh::Host.new(hostname, ssh_options)
    else
      @hosts[host_alias] = Rosh::Host.new(hostname, ssh_options)
    end
  end

  def self.hosts
    @hosts
  end

  def self.config
    return @config if @config

    if File.exists? DEFAULT_RC_FILE
      erb = ERB.new(File.read(DEFAULT_RC_FILE))
      @config = YAML.load(erb.result)
    end
  end

  def self.reset
    @hosts = {}
    @config = nil
  end
end
