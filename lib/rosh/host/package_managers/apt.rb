require_relative '../package_types/deb'
require_relative 'dpkg'


class Rosh
  class Host
    module PackageManagers
      module Apt
        include Dpkg
        DEFAULT_BIN_PATH = '/usr/bin'

        def bin_path
          @bin_path ||= DEFAULT_BIN_PATH
        end

        # Creates a new Apt package by name.
        #
        # @param [String] name
        #
        # @return [Rosh::Host::PackageTypes::Deb]
        def create_package(name, **options)
          Rosh::Host::Package.new(:deb, name, @host_name, **options)
        end

        # Updates Apt's package index using `apt-get update`.
        #
        # @return [String] Output from the shell command.
        def update_definitions_command
          'apt-get update'
        end

        # Upgrades outdated packages using `apt-get upgrade -y`.
        #
        # @return [String] Output of the upgrade command.
        def upgrade_packages_command
          'apt-get upgrade -y DEBIAN_FRONTEND=noninteractive'
        end

        private

        # Extracts the list of updated package definitions from the output of
        # a #update_definitions call.
        #
        # @param [String] output from the #update_defintions call.
        # @return [Array<Hash{source: String, distribution: String, components: Array, size: String}]
        # TODO: How to deal with output being an Exception?
        def extract_updated_definitions(output)
          return [] unless output.is_a? String

          updated = []

          output.each_line do |line|
            next unless line.start_with?('Get:')

            %r(Get:\d\s+(?<get_source>\S+)\s(?<distro>\S+)\s(?<components>[^\[]+)\s\[(?<size>[^\]]+)) =~ line

            updated << {
              source: get_source,
              distribution: distro,
              components: components.split(' '),
              size: size
            }
          end

          updated.compact
        end

        # Extracts Deb package names for #upgrade_packages from the command
        # output.
        #
        # @param [String] output Output from the apt-get upgrade command.
        # @return [Array<String>]
        def extract_upgraded_packages(output)
          new_packages = []

          output.each_line do |line|
            next if line.match(/The following packages will be upgraded:/)
            break if line.match(/\d+ upgraded, \d+ newly installed/)

            line.split.each do |pkg|
              new_packages << create_package(pkg)
            end
          end

          new_packages
        end
      end
    end
  end
end
