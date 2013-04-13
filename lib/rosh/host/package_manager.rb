Dir[File.dirname(__FILE__) + '/package_types/*.rb'].each(&method(:require))


class Rosh
  class Host
    class PackageManager
      def initialize(host)
        @host = host
      end

      def [](package_name)
        create(package_name)
      end

      def list
        result = @host.shell.exec 'brew list'

        pkgs = result.split("\n").map do |pkg|
          create(pkg)
        end

        pkgs
      end

      private

      def create(name)
        case @host.operating_system
        when :darwin
          Rosh::Host::PackageTypes::Brew.new(@host.shell, name)
        end
      end
    end
  end
end
