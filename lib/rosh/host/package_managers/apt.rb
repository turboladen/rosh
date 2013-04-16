require_relative '../package_types/apt'


class Rosh
  class Host
    module PackageManagers
      module Apt
        def update_cache
          @shell.exec 'apt-get update'

          @shell.history.last[:exit_status].zero?
        end

        def update_packages
          @shell.exec 'apt-get upgrade'

          @shell.history.last[:exit_status].zero?
        end

        private

        def create(name)
          Rosh::Host::PackageTypes::Apt.new(@shell, name)
        end
      end
    end
  end
end
