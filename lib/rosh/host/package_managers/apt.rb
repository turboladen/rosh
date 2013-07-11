require_relative '../package_types/deb'


class Rosh
  class Host
    module PackageManagers
      module Apt

        # Updates APT's package index using `apt-get update`.  Notifies
        # observers with Arrays of old sources (that weren't updated) and
        # updated sources.
        #
        # @return [Boolean] +true+ if exit status was 0; +false+ if not.
        def update_index
          output = @shell.exec 'apt-get update'

          not_updated = []
          updated = []

          output.each_line do |line|
            /Hit\s+(?<hit_source>.+)/ =~ line
            if hit_source
              not_updated << hit_source
              next
            end

            /Get:\d\s+(?<get_source>.+)/ =~ line
            updated << get_source if get_source
          end

          success = @shell.last_exit_status.zero?

          if success && !updated.empty?
            changed
            notify_observers(self,
              attribute: :index, old: not_updated, new: updated,
              as_sudo: @shell.su?)
          end

          success
        end

        # Upgrades outdated packages using `apt-get upgrade -y`.  Notifies
        # observers with packages that were updated.  The list of packages in
        # the update notification is an Array of Rosh::Host::PackageTypes::Deb
        # objects.
        #
        # @return [Boolean] +true+ if exit status was 0; +false+ if not.
        def upgrade_packages
          old_packages = installed_packages
          output = @shell.exec 'apt-get upgrade -y DEBIAN_FRONTEND=noninteractive'
          new_package_names = extract_upgradable_packages(output)
          success = @shell.last_exit_status.zero?

          if success && !new_package_names.empty?
            new_packages = new_package_names.map(&method(:create))
            changed
            notify_observers(self,
              attribute: :installed_packages, old: old_packages,
              new: new_packages, as_sudo: @shell.su?)
          end

          success
        end

        private

        # Extracts Deb package names for #upgrade_packages from the command
        # output.
        #
        # @param [String] output Output from the apt-get upgrade command.
        # @return [Array<String>]
        def extract_upgradable_packages(output)
          new_packages = []

          output.each_line do |line|
            next if line.match(/The following packages will be upgraded:/)
            break if line.match(/\d+ upgraded, \d+ newly installed/)

            line.split.each do |pkg|
              new_packages << pkg
            end
          end

          new_packages
        end

        # Creates a new Apt package by name.
        #
        # @param [String] name
        #
        # @return [Rosh::Host::PackageTypes::Deb]
        def create(name, **options)
          Rosh::Host::PackageTypes::Deb.new(name, @shell, **options)
        end
      end
    end
  end
end
