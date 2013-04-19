require 'observer'

require_relative '../package_types/apt'


class Rosh
  class Host
    module PackageManagers
      module Apt
        include Observable

        # Updates APT's cache using `apt-get update`.
        #
        # @return [Boolean] +true+ if exit status was 0; +false+ if not.
        def update_cache
          output = @shell.exec 'apt-get update'

          updated_lines = output.each_line.map do |line|
            line.strip if line.match(/^Get:/)
          end.compact

          unless updated_lines.empty?
            changed
            notify_observers(self, :update_cache, nil, updated_lines)
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
            notify_observers(self, :upgrade_packages, nil, packages)
          end

          @shell.history.last[:exit_status].zero?
        end

        private

        # Creates a new Apt package by name.
        #
        # @param [String] name
        #
        # @return [Rosh::Host::PackageTypes::Apt]
        def create(name)
          Rosh::Host::PackageTypes::Apt.new(@shell, name)
        end
      end
    end
  end
end
