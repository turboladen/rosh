require_relative '../package'
require_relative '../package_types/deb'


class Rosh
  class Host
    module PackageManagers
      module Dpkg

        # Creates a new deb package by name.
        #
        # @param [String] name
        #
        # @return [Rosh::Host::PackageTypes::Deb]
        def create_package(name, **options)
          Rosh::Host::Package.new(:deb, name, @host_name, **options)
        end

        # @return [Array<Rosh::Host::PackageTypes::Deb>]
        def installed_packages
          result = current_shell.exec 'dpkg --list'

          result.split("\n").map do |pkg|
            if pkg.match(/^[A-za-z]{1,3}\s+/)
              %r[(?<status>[\w]{1,3})\s+(?<name>\S+)\s+(?<version>\S+)\s+(?<description>[^\n]+)] =~
                pkg

              create_package(name, version: version, status: status)
            end
          end.compact
        end
      end
    end
  end
end
