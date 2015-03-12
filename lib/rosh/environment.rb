require_relative 'host'

class Rosh
  class Environment
    # @return [Hash{Object => Rosh::Host}]
    attr_reader :hosts

    def initialize
      @hosts = {}
      @current_host = nil
    end

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
    def add_host(host_name, host_label: nil, **ssh_options)
      new_host = if host_label.nil?
        @hosts[host_name] = Rosh::Host.new(host_name, ssh_options)
      else
        @hosts[host_label] = Rosh::Host.new(host_name, ssh_options)
      end

      @current_host ||= new_host

      new_host
    end

    # Returns the Rosh::Host base on the current @host_name.
    #
    # @return [Rosh::Host]
    def current_host
      @current_host
    end

    def current_host=(host)
      @current_host = host
    end

    # Returns the Rosh::Host::Shells::* shell based on the host name.
    #
    # @return [Rosh::Host::Shells::*]
    def current_shell
      current_host.shell
    end

    def current_user
      current_host.user
    end
  end
end
