require 'yaml'
require_relative 'host'


class Rosh
  class Environment
    def self.hosts
      return @hosts if @hosts

      if ::File.exists? 'rosh_config.yml'
        config = YAML.load_file 'rosh_config.yml'
      end

      puts "reading hosts"
      p config[:hosts]
      @hosts = {}

      config[:hosts].each do |hostname, options|
        puts "hostname: #{hostname}"
        puts "optison: #{options}"
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

    def self.command_history
      @command_history ||= []
    end
  end
end
