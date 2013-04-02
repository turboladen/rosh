require 'yaml'
require 'erb'
require 'etc'
require 'log_switch'
require_relative 'host'


class Rosh
  class Environment
    extend LogSwitch

    def self.config
      return @config if @config

      if ::File.exists? 'rosh_config.yml'
        erb = ERB.new(::File.read('rosh_config.yml'))
        @config = YAML.load(erb.result)
      end
    end

    def self.hosts
      return @hosts if @hosts

      @hosts = {}

      config[:hosts].each do |hostname, options|
        self.log "Read hostname: #{hostname}"
        self.log "Read options: #{options}"
        @hosts[hostname] = Rosh::Host.new(hostname, **options)
      end

      @hosts
    end

    def self.current_host
      @hosts[@current_hostname]
    end

    def self.current_hostname=(hostname)
      @current_hostname = hostname
    end

    def self.path
      config[:path]
    end

    private

    def self.get_binding
      binding
    end
  end
end
