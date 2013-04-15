require_relative '../package_types/dpkg'


class Rosh
  class Host
    module PackageManagers
      module Dpkg

        def list
          result = @shell.exec 'dpkg --list'

          result.split("\n").map do |pkg|
            if pkg.match(/^[A-za-z]{1,3}\s+/)
              %r[(?<status>[\w]{1,3})\s+(?<name>\S+)\s+(?<version>\S+)\s+(?<description>[^\n]+)] =~
                pkg

              {
                status: status,
                name: name,
                version: version,
                description: description
              }
            end
          end.compact
        end

        private

        def create(name)
          Rosh::Host::PackageTypes::Dpkg.new(@shell, name)
        end
      end
    end
  end
end
