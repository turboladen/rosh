require_relative 'rosh/logger'
require_relative 'rosh/host'
require_relative 'rosh/internal_helpers'
require_relative 'rosh/environment'

class Rosh
  DEFAULT_RC_FILE = Dir.home + '/.roshrc'
  @@environment ||= Rosh::Environment.new

  def self.environment
    @@environment
  end

  # The currently managed Rosh::Hosts.
  #
  # @return [Hash{String,Object => Rosh::Host}]
  def self.hosts
    @@environment.hosts
  end

  # Finds the registered Rosh::Host with the given +host_name+.
  #
  # @param [String] host_name
  # @return [Rosh::Host] +nil+ if host_name not registered.
  def self.find_by_host_name(host_name)
    key_value_pair = @@environment.hosts.find do |_, host|
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

  include InternalHelpers
end
