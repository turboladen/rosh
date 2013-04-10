require_relative 'service'
Dir[File.dirname(__FILE__) + '/service_types/*.rb'].each(&method(:require))


class Rosh
  class Host
    class ServiceManager
      def initialize(host)
        @host = host
      end

      def [](service_name)
        create(service_name)
      end

      def list
        case @host.operating_system
        when :darwin
          #darwin_list
        when :linux
          linux_list
        when :freebsd
          freebsd_list
        end
      end

      private

      def create(name)
        case @host.operating_system
        when :darwin
          Rosh::Host::ServiceTypes::LaunchCTL.new(name, @host)
        when :linux
          Rosh::Host::ServiceTypes::Init.new(name, @host)
        when :freebsd
          Rosh::Host::ServiceTypes::Init.new(name, @host)
        end
      end

      def linux_list
        result = @host.shell.ls '/etc/init.d'

        services = result.ruby_object.map do |file|
          create(file.basename)
        end

        Rosh::CommandResult.new(services, 0, result.ssh_result)
      end

      def freebsd_list
        result = @host.shell.ls '/etc/rc.d'

        services = result.ruby_object.map do |file|
          create(file.basename)
        end

        Rosh::CommandResult.new(services, 0, result.ssh_result)
      end

=begin
      def darwin_list
        result = @host.shell.exec('launchctl list')

        result.ruby_object.each_line do |line|
          next if line =~ /^PID/

          line =~ /(?<pid>\d+)\s+(?<status>\S*)\s+(?<label>[^\n]+)/
        end
      end
=end
    end
  end
end
