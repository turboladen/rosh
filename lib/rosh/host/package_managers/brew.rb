require_relative 'base'
require_relative '../package_types/brew'


class Rosh
  class Host
    module PackageManagers
      class Brew < Base

        # Lists all installed Brew packages.
        #
        # @return [Array<Rosh::Host::PackageTypes::Brew>]
        def installed_packages
          output = @shell.exec 'brew list'

          output.split(/\s+/).map do |pkg|
            create_package(pkg)
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
            notify_observers(self,
              attribute: :index, old: [], new: updated, as_sudo: @shell.su?)
          end

          success
        end

        # Upgrades outdated packages using `brew upgrade`.
        #
        # @return [String] Output of the upgrade command.
        def upgrade_packages
          @shell.exec 'brew upgrade'
        end

        def create_package(name, **options)
          Rosh::Host::PackageTypes::Brew.new(name, @shell, **options)
        end

        # Extracts Brew package names for #upgrade_packages from the command
        # output.
        #
        # @param [String] output Output from the brew upgrade command.
        # @return [Array<String>]
        def extract_upgraded_packages(output)
          /Upgrading \d+ outdated packages, with result:\n(?<list>[^=>]+)/ =~ output

          name_and_version = list.split(', ')
          name_and_version.map do |pkg|
            /(?<name>\S+)/ =~ pkg

            name
          end
        end
      end
    end
  end
end
