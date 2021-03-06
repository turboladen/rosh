require_relative 'rosh/host'


class Rosh
  DEFAULT_RC_FILE = Dir.home + '/.roshrc'
  @hosts = {}
  @config = nil

  # Adds a new Rosh::Host for Rosh to manage.
  #
  # @param [String] host_name Name or IP of the host to add.
  # @param host_label Any object to refer to the Host as.  Allows for shortcuts
  #   to referring to the host_name.
  #
  # @example Add by host_name only
  #   Rosh.add_host 'super-duper-server.example.com', user: 'robby', password: 'stuff'
  #   Rosh.hosts['super-duper-server.example.com'].name   # => 'super-duper-server.example.com'
  #
  # @example Add by label only
  #   Rosh.add_host 'super-duper-server.example.com', host_label: :super,
  #     user: 'robby', password: 'stuff'
  #   Rosh.hosts[:super'].name      # => 'super-duper-server.example.com'
  def self.add_host(host_name, host_label: nil, **ssh_options)
    if host_label.nil?
      @hosts[host_name] = Rosh::Host.new(host_name, ssh_options)
    else
      @hosts[host_label] = Rosh::Host.new(host_name, ssh_options)
    end
  end

  # The currently managed Rosh::Hosts.
  #
  # @return [Hash{String,Object => Rosh::Host}]
  def self.hosts
    @hosts
  end

  # Finds the registered Rosh::Host with the given +host_name+.
  #
  # @param [String] host_name
  # @return [Rosh::Host] +nil+ if host_name not registered.
  def self.find_by_host_name(host_name)
    key_value_pair = @hosts.find do |_, host|
      host.name == host_name
    end

    key_value_pair.last rescue nil
  end

  # Reads the configuration from .roshrc.yml.
  #
  # @return [Hash]
  def self.load_config
    @config = if File.exists? DEFAULT_RC_FILE
      File.read(DEFAULT_RC_FILE)
    end
  end

  # @return [Hash]
  def self.config
    @config
  end

  # Resets hosts and configuration to empty values.
  def self.reset
    @hosts = {}
    @config = nil
  end
end
