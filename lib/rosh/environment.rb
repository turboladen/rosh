require_relative 'host'

class Rosh
  # The internal environment for Rosh. Contains info about what's current and
  # what Rosh knows about.
  class Environment
    # @return [Hash{Object => Rosh::Host}]
    attr_reader :hosts

    # !@attribute [rw] current_host
    #
    #   Returns the Rosh::Host base on the current @host_name.
    #   @return [Rosh::Host]
    attr_accessor :current_host

    def initialize
      @hosts = {}
      @current_host = nil
    end

    # Adds a new Rosh::Host for Rosh to manage.
    #
    # @param [String] host_name Name or IP of the host to add.
    # @param host_label Any object to refer to the Host as.  Allows for
    #   shortcuts to referring to the host_name.
    # @param [Hash] ssh_options Any options supported by Net::SSH to use for
    #   when adding a remote host.
    #
    # @example Add by host_name only
    #   Rosh.add_host 'super-duper-server.example.com', user: 'robby',
    #                                                   password: 'stuff'
    #   Rosh.hosts['super-duper-server.example.com'].name
    #     # => 'super-duper-server.example.com'
    #
    # @example Add by label only
    #   Rosh.add_host 'super-duper-server.example.com', host_label: :super,
    #     user: 'robby', password: 'stuff'
    #   Rosh.hosts[:super'].name      # => 'super-duper-server.example.com'
    # @return [Rosh::Host]
    def add_host(host_name, host_label: nil, **ssh_options)
      new_host = if host_label.nil?
                   @hosts[host_name] = Rosh::Host.new(host_name, ssh_options)
                 else
                   @hosts[host_label] = Rosh::Host.new(host_name, ssh_options)
                 end

      @current_host ||= new_host

      new_host
    end

    # Finds the registered Rosh::Host with the given +host_name+.
    #
    # @param [String] host_name
    # @return [Rosh::Host] +nil+ if host_name not registered.
    def find_by_host_name(host_name)
      key_value_pair = @hosts.find do |_, host|
        host.name == host_name
      end

      key_value_pair.try(:last)
    end

    # Returns the Rosh::Host::Shells::* shell based on the host name.
    #
    # @return [Rosh::Host::Shells::*]
    def current_shell
      @current_host.shell
    end

    def current_user
      @current_host.user
    end
  end
end
