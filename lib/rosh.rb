require_relative 'rosh/logger'
require_relative 'rosh/host'
require_relative 'rosh/internal_helpers'
require_relative 'rosh/environment'

# Contains methods for configuring and checking config.
class Rosh
  DEFAULT_RC_FILE = ::File.join(Dir.home, '.roshrc')

  @environment ||= Rosh::Environment.new

  class << self
    extend Forwardable

    # @!attribute [r] environment
    #   @return [Rosh::Environment]
    attr_reader :environment

    attr_reader :config

    # @!attribute [r] hosts
    #   The currently managed Rosh::Hosts.
    #   @return [Hash{String,Object => Rosh::Host}]
    def_delegator :@environment, :hosts

    # Reads the configuration from .roshrc.yml.
    #
    # @return [Hash]
    def load_config
      @config = ::File.read(DEFAULT_RC_FILE) if ::File.exist?(DEFAULT_RC_FILE)
    end

    def reset!
      @environment = Rosh::Environment.new
    end

    private
  end

  include InternalHelpers
end
