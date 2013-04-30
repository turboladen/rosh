require_relative '../package_types/deb'


class Rosh
  class Host
    module PackageManagers
      module Dpkg

        # @return [Array<Rosh::Host::PackageTypes::Deb>]
        def installed_packages
          result = @shell.exec 'dpkg --list'

          result.split("\n").map do |pkg|
            if pkg.match(/^[A-za-z]{1,3}\s+/)
              %r[(?<status>[\w]{1,3})\s+(?<name>\S+)\s+(?<version>\S+)\s+(?<description>[^\n]+)] =~
                pkg

              create(name, version: version, status: status)
            end
          end.compact
        end

        private

        # @param [String] name
        # @param [Hash] options
        def create(name, **options)
          Rosh::Host::PackageTypes::Deb.new(name, @shell, **options)
        end
      end
    end
  end
end
