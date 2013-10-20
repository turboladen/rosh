require_relative 'base'
require_relative '../package'


class Rosh
  class PackageManager
    module ManagerAdapters
      class Yum
        DEFAULT_BIN_PATH = '/usr/bin'
        include Base

        class << self

          # Lists all installed Rpm packages.
          #
          # @return [Array<Rosh::Host::PackageTypes::Rpm>]
          def installed_packages
            output = current_shell.exec 'yum list'

            output.each_line.map do |line|
              /^(?<name>\S+)\.(?<arch>\S+)\s+(?<version>\S+)\s+(?<status>\S*)/ =~ line
              next unless name

              Rosh::PackageManager::Package.new(name, @host_name)
            end
          end

          def update_definitions
            current_shell.exec %[#{bin_path}/yum check-update]
          end

          def upgrade_packages
            current_shell.exec %[#{bin_path}/yum update -y]
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
end
