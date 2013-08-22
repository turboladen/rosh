require_relative 'base'
require_relative '../package_types/rpm'


class Rosh
  class Host
    module PackageManagers
      class Yum < Base

        # Lists all installed Rpm packages.
        #
        # @return [Array<Rosh::Host::PackageTypes::Rpm>]
        def installed_packages
          output = current_shell.exec 'yum list'

          output.each_line.map do |line|
            /^(?<name>\S+)\.(?<arch>\S+)\s+(?<version>\S+)\s+(?<status>\S*)/ =~ line
            puts "name: #{name}"
            next unless name

            create_package(name, architecture: arch, version: version, status: status)
          end
        end

        # Updates Yum's package index using `yum check-update`.
        #
        # @return [String] output from the shell command.
        def update_definitions
          current_shell.exec 'yum check-update'
        end

        # Extracts the list of updated package definitions from the output of
        # a #update_definitions call.
        #
        # @param [String] output from the #update_defintions call.
        # @return [Array<Hash{package: String, architecture: String, version: String, repository: String}>]
        # TODO: How to deal with output being an Exception?
        def _extract_updated_definitions(output)
          return [] unless output.is_a? String
          return [] unless output.match(/\n\n/)

          _, packages = output.split("\n\n")

          packages.each_line.map do |line|
            /^(?<pkg>[^\.]+)\.(?<arch>\S+)\s+(?<version>\S+)\s+(?<repo>\S+)/ =~ line

            { package: pkg, architecture: arch, version: version, repository: repo }
          end
        end

        # Upgrades outdated packages using `yum update -y`.
        #
        # @return [String] Output of the upgrade command.
        def upgrade_packages
          current_shell.exec 'yum update -y'
        end

        def create_package(name, **options)
          Rosh::Host::PackageTypes::Rpm.new(name, current_shell, **options)
        end

        # Extracts Rpm packagesnames for #upgrade_packages from the command
        # output.
        #
        # @param [String] output Output from the yum update command.
        # @return [Array<Rosh::Host::PackageTypes::Rpm>]
        def _extract_upgraded_packages(output)
          output.each_line.map do |line|
            /Package (?<name>\S+)\.(?<arch>\S+)\s+(?<version>\S+).*to be / =~ line
            next unless name
            puts "name: #{name}"

            create_package(name, version: version, architecture: arch)
          end.compact
        end
      end
    end
  end
end
