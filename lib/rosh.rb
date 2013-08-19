require 'yaml'
require_relative 'rosh/host'


class Rosh
  DEFAULT_RC_FILE = Dir.home + '/.roshrc'
  @hosts = {}
  @config = nil

  # Adds a new Rosh::Host for Rosh to manage.
  #
  # @param [String] hostname Name or IP of the host to add.
  # @param host_alias Any object to refer to the Host as.  Allows for shortcuts
  #   to referring to the hostname.
  #
  # @example Add by hostname only
  #   Rosh.add_host 'super-duper-server.example.com', user: 'robby', password: 'stuff'
  #   Rosh.hosts['super-duper-server.example.com'].hostname   # => 'super-duper-server.example.com'
  #
  # @example Add by alias only
  #   Rosh.add_host 'super-duper-server.example.com', host_alias: :super,
  #     user: 'robby', password: 'stuff'
  #   Rosh.hosts[:super'].hostname      # => 'super-duper-server.example.com'
  def self.add_host(hostname, host_alias: nil, **ssh_options)
    if host_alias.nil?
      @hosts[hostname] = Rosh::Host.new(hostname, ssh_options)
    else
      @hosts[host_alias] = Rosh::Host.new(hostname, ssh_options)
    end
  end

  # The currently managed Rosh::Hosts.
  #
  # @return [Hash{String,Object => Rosh::Host}]
  def self.hosts
    @hosts
  end

  # Reads the configuration from .roshrc.yml.
  #
  # @return [Hash]
  def self.config
    return @config if @config

    @config = if File.exists? DEFAULT_RC_FILE
      File.read(DEFAULT_RC_FILE)
    end
  end

  # Resets hosts and configuration to empty values.
  def self.reset
    @hosts = {}
    @config = nil
  end
end
