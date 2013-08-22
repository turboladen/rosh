require_relative 'rosh/host'


class Rosh
  DEFAULT_RC_FILE = Dir.home + '/.roshrc'
  @hosts = {}
  @config = nil

  # Adds a new Rosh::Host for Rosh to manage.
  #
  # @param [String] hostname Name or IP of the host to add.
  # @param host_label Any object to refer to the Host as.  Allows for shortcuts
  #   to referring to the hostname.
  #
  # @example Add by hostname only
  #   Rosh.add_host 'super-duper-server.example.com', user: 'robby', password: 'stuff'
  #   Rosh.hosts['super-duper-server.example.com'].name   # => 'super-duper-server.example.com'
  #
  # @example Add by label only
  #   Rosh.add_host 'super-duper-server.example.com', host_label: :super,
  #     user: 'robby', password: 'stuff'
  #   Rosh.hosts[:super'].name      # => 'super-duper-server.example.com'
  def self.add_host(hostname, host_label: nil, **ssh_options)
    if host_label.nil?
      @hosts[hostname] = Rosh::Host.new(hostname, ssh_options)
    else
      @hosts[host_label] = Rosh::Host.new(hostname, host_label, ssh_options)
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
