require_relative '../package_types/rpm'


class Rosh
  class Host
    module PackageManagers
      module Yum

        # Lists all installed Rpm packages.
        #
        # @return [Array<Rosh::Host::PackageTypes::Rpm>]
        def installed_packages
          output = @shell.exec 'yum list'

          output.each_line.map do |line|
            /^(?<name>\S+)\.(?<arch>\S+)\s+(?<version>\S+)\s+(?<status>\S*)/ =~ line
            puts "name: #{name}"
            next unless name

            create(name, architecture: arch, version: version, status: status)
          end
        end

        def update_index
          @shell.exec 'yum check-update -y'

          @shell.last_exit_status.zero?
        end

        # Upgrades outdated packages using `yum update -y`.  Notifies
        # observers with packages that were updated.  The list of packages in
        # the update notification is an Array of Rosh::Host::PackageTypes::Rpm
        # objects.
        #
        # @return [Boolean] +true+ if exit status was 0; +false+ if not.
        def upgrade_packages
          old_packages = installed_packages
          output = @shell.exec 'yum update -y'
          new_packages = extract_upgradable_packages(output)
          success = @shell.last_exit_status.zero?

          if success && !new_packages.empty?
            changed
            notify_observers(self, attribute: :installed_packages,
              old: old_packages, new: new_packages)
          end

          success
        end

        private

        # Extracts Rpm packagesnames for #upgrade_packages from the command
        # output.
        #
        # @param [String] output Output from the yum update command.
        # @return [Array<Rosh::Host::PackageTypes::Rpm>]
        def extract_upgradable_packages(output)
          output.each_line.map do |line|
            /Package (?<name>\S+)\.(?<arch>\S+)\s+(?<version>\S+).*to be / =~ line
            next unless name
            puts "name: #{name}"

            create(name, version: version, architecture: arch)
          end.compact
        end

        def create(name, **options)
          Rosh::Host::PackageTypes::Rpm.new(name, @shell, **options)
        end
      end
    end
  end
end
