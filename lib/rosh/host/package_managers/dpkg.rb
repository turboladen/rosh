require_relative 'base'
require_relative '../package_types/deb'


class Rosh
  class Host
    module PackageManagers
      # TODO: Figure out if this should go in Apt.
      class Dpkg < Base

        # @return [Array<Rosh::Host::PackageTypes::Deb>]
        def installed_packages
          result = @shell.exec 'dpkg --list'

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
