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

        # Updates APT's cache using `apt-get update`.  Notifies observers with
        # packages updated in the cache.  The list of updated packages in the
        # update notification is an Array of Rosh::Host::PackageTypes::Deb
        # objects.
        #
        # @return [Boolean] +true+ if exit status was 0; +false+ if not.
        # @todo The list of packages should be of Deb objects.
        def update_cache
          before = cache
          @shell.exec 'apt-get update'
          after = cache
          difference = after - before
          success = @shell.last_exit_status.zero?

          if success && !difference.empty?
            changed
            notify_observers(self, attribute: :cache, old: before, new: after)
          end

          success
        end

        # Upgrades outdated packages using `apt-get upgrade -y`.  Notifies
        # observers with packages that were updated.  The list of packages in
        # the update notification is an Array of Rosh::Host::PackageTypes::Deb
        # objects.
        #
        # @return [Boolean] +true+ if exit status was 0; +false+ if not.
        def upgrade_packages
          old_packages = packages
          output = @shell.exec 'apt-get upgrade -y'
          new_package_names = extract_upgradable_packages(output)
          success = @shell.last_exit_status.zero?

          if success && !new_package_names.empty?
            new_packages = new_package_names.map(&method(:create))
            changed
            notify_observers(self, attribute: :packages, old: old_packages,
              new: new_packages)
          end

          success
        end

        private

        # Extracts Deb package names for #upgrade_packages from the command
        # output.
        #
        # @param [String] output Output from the apt-get upgrade command.
        # @return [Array<String>]
        def extract_upgradable_packages(output)
          new_packages = []

          output.each_line do |line|
            next if line.match(/The following packages will be upgraded:/)
            break if line.match(/\d+ upgraded, \d+ newly installed/)

            line.split.each do |pkg|
              new_packages << pkg
            end
          end

          new_packages
        end

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
