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

        result.split(/\s+/).map do |pkg|
          create(pkg)
        end
      end

      def update
        @host.shell.exec 'brew update'

        @host.shell.history.last[:exit_status].zero?
      end

      # @param [String,Regexp] text
      # @return [Array]
      def search(text=nil)
        text = "/#{text.source}/" if text.is_a? Regexp

        result = @host.shell.exec("brew search #{text}")

        # For some reason, doing this causes a memory leak and Ruby blows up.
        #packages = result.split(/\s+/).map do |pkg|
        #  puts "package #{pkg}"
        #  create(pkg)
        #end

        result.split(/\s+/)
      end

      private

      def create(name)
        case @host.operating_system
        when :darwin
          Rosh::Host::PackageTypes::Brew.new(@host.shell, name)
        else
          raise "Unknown operating system: #{@host.operating_system}"
        end
      end
    end
  end
end
