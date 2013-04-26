require 'observer'

require_relative '../package_types/deb'


class Rosh
  class Host
    module PackageManagers
      module Apt
        include Observable

        # Lists all packages that exist in the apt cache.
        #
        # @return [Array<Rosh::Host::PackageTypes::Deb>]
        def cache
          output = @shell.exec "apt-cache dump | grep 'Package:\||*Version:'"
          cached_packages = {}

          output.each_line do |line|
            if line.strip.match /Package: [^\n]+/
              /Package: (?<name>[^:]+):?(?<arch>\S*)/ =~ line
              cached_packages[name.strip] ||= {}
              cached_packages[name.strip][:architecture] = arch.strip
            elsif line.strip.match /Version: (?<version>\S+)/
              last_pkg = cached_packages.keys.last
              cached_packages[last_pkg][:version] = $~[:version]
            end
          end

          cached_packages.map do |name, attributes|
            create(name, attributes)
          end
        end

        #
        # @return [Boolean] +true+ if exit status was 0; +false+ if not.
        def update_cache
          output = @shell.exec 'apt-get update'

          updated_lines = output.each_line.map do |line|
            line.strip if line.match(/^Get:/)
          end.compact

          unless updated_lines.empty?
            changed
            notify_observers(self, attribute: :update_cache, old: nil, new: updated_lines)
          end

          @shell.history.last[:exit_status].zero?
        end

        # Upgrades outdated packages using `apt-get upgrade -y`.
        #
        # @return [Boolean] +true+ if exit status was 0; +false+ if not.
        def upgrade_packages
          output = @shell.exec 'apt-get upgrade -y'
          packages = []

          output.each_line do |line|
            next if line.match(/The following packages will be upgraded:/)
            break if line.match(/\d+ upgraded, \d+ newly installed/)

            line.split.each do |pkg|
              packages << create(pkg)
            end
          end

          unless packages.empty?
            changed
            notify_observers(self, attribute: :upgrade_packages, old: nil, new: packages)
          end

          @shell.history.last[:exit_status].zero?
        end

        private

        # Creates a new Apt package by name.
        #
        # @param [String] name
        #
        # @return [Rosh::Host::PackageTypes::Deb]
        def create(name, **options)
          Rosh::Host::PackageTypes::Deb.new(name, @shell, **options)
        end
      end
    end
  end
end
