require_relative '../package_types/rpm'
require_relative '../package'


class Rosh
  class Host
    module PackageManagers
      module Yum
        DEFAULT_BIN_PATH = '/usr/bin'

        def bin_path
          @bin_path ||= DEFAULT_BIN_PATH
        end

        def create_package(name, **options)
          Rosh::Host::Package.new(:rpm, name, @host_name, **options)
        end

        # Lists all installed Rpm packages.
        #
        # @return [Array<Rosh::Host::PackageTypes::Rpm>]
        def installed_packages
          output = current_shell.exec 'yum list'

          output.each_line.map do |line|
            /^(?<name>\S+)\.(?<arch>\S+)\s+(?<version>\S+)\s+(?<status>\S*)/ =~ line
            next unless name

            create_package(name, architecture: arch, version: version, status: status)
          end
        end

        # Updates Yum's package index using `yum check-update`.
        #
        # @return [String] output from the shell command.
        def update_definitions_command
          'yum check-update'
        end

        # Upgrades outdated packages using `yum update -y`.
        #
        # @return [String] Output of the upgrade command.
        def upgrade_packages_command
          'yum update -y'
        end

        private

        # Extracts the list of updated package definitions from the output of
        # a #update_definitions call.
        #
        # @param [String] output from the #update_defintions call.
        # @return [Array<Hash{package: String, architecture: String, version: String, repository: String}>]
        # TODO: How to deal with output being an Exception?
        def extract_updated_definitions(output)
          return [] unless output.is_a? String
          return [] unless output.match(/\n\n/)

          _, packages = output.split("\n\n")

          packages.each_line.map do |line|
            /^(?<pkg>[^\.]+)\.(?<arch>\S+)\s+(?<version>\S+)\s+(?<repo>\S+)/ =~ line

            { package: pkg, architecture: arch, version: version, repository: repo }
          end
        end

        # Extracts Rpm packagesnames for #upgrade_packages from the command
        # output.
        #
        # @param [String] output Output from the yum update command.
        # @return [Array<Rosh::Host::PackageTypes::Rpm>]
        def extract_upgraded_packages(output)
          output.each_line.map do |line|
            /Package (?<name>\S+)\.(?<arch>\S+)\s+(?<version>\S+).*to be / =~ line
            next unless name

            create_package(name, version: version, architecture: arch)
          end.compact
        end
      end
    end
  end
end
