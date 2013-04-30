require_relative '../package_types/brew'


class Rosh
  class Host
    module PackageManagers
      module Brew

        # Lists all packages that exist in the homebrew cache.
        #
        # @return [Hash{ String => Hash }]
        def cache
          output = @shell.exec 'ls `brew --cache`'
          cached_packages = {}

          output.split.each do |pkg|
            /^(?<name>\w*(-\w*)?)-(?<version>(\d+[^\.]*\.)+)/ =~ pkg
            puts "name: #{name}"
            puts "version: #{version}"

            next unless name
            version.chomp!('.') if version
            cached_packages[name.strip] = { arch: '', version: version.strip }
          end

          @cache = Hash[cached_packages.sort]
        end

        # Lists all installed Brew packages.
        #
        # @return [Array<Rosh::Host::PackageTypes::Brew>]
        def installed_packages
          output = @shell.exec 'brew list'

          output.split(/\s+/).map do |pkg|
            create(pkg)
          end
        end

        # Updates homebrew's package index using `brew update`.  Notifies
        # observers with lists of new, updated, and deleted packages from the
        # index.
        #
        # @return [Boolean] +true+ if exit status was 0; +false+ if not.
        def update_index
          output = @shell.exec 'brew update'

          /==> New Formulae\n(?<new_formulae>[^=>]*)/m =~ output
          /==> Updated Formulae\n(?<updated_formulae>[^=>]*)/m =~ output
          /==> Deleted Formulae\n(?<deleted_formulae>[^=>]*)/m =~ output

          updated = []
          updated << { new_formulae: new_formulae.split } if new_formulae

          if updated_formulae
            updated << { updated_formulae: updated_formulae.split }
          end

          if deleted_formulae
            updated << { deleted_formulae: deleted_formulae.split }
          end

          success = @shell.last_exit_status.zero?

          if success && !updated.empty?
            changed
            notify_observers(self, attribute: :index, old: [], new: updated)
          end

          success
        end

        # Upgrades outdated packages using `brew upgrade`.  Notifies
        # observers with packages that were updated.  The list of packages in
        # the update notification is an Array of Rosh::Host::PackageTypes::Brew
        # objects.
        #
        # @return [Boolean] +true+ if exit status was 0; +false+ if not.
        def upgrade_packages
          old_packages = installed_packages
          output = @shell.exec 'brew upgrade'
          new_package_names = extract_upgradable_packages(output)
          success = @shell.last_exit_status.zero?

          if success && !new_package_names.empty?
            new_packages = new_package_names.map(&method(:create))
            changed
            notify_observers(self, attribute: :installed_packages,
              old: old_packages, new: new_packages)
          end

          success
        end

        private

        # Extracts Brew package names for #upgrade_packages from the command
        # output.
        #
        # @param [String] output Output from the brew upgrade command.
        # @return [Array<String>]
        def extract_upgradable_packages(output)
          /Upgrading \d+ outdated packages, with result:\n(?<list>[^=>]+)/ =~ output

          name_and_version = list.split(', ')
          name_and_version.map do |pkg|
            /(?<name>\S+)/ =~ pkg

            name
          end
        end

        def create(name)
          Rosh::Host::PackageTypes::Brew.new(@shell, name)
        end
      end
    end
  end
end
