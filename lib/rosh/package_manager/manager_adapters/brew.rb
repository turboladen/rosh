require_relative '../package'


class Rosh
  class PackageManager
    module ManagerAdapters
      module Brew
        DEFAULT_BIN_PATH = '/usr/local/bin'

        # Lists all installed Brew packages.
        #
        # @return [Array<Rosh::Host::PackageTypes::Brew>]
        def installed_packages
          output = current_shell.exec("#{@bin_path}/brew list")

          output.split(/\s+/).map do |pkg|
            Rosh::PackageManager::Package.new(pkg, @host_name)
          end
        end

        # @return [Array]
        def update_definitions
          output = current_shell.exec "#{@bin_path}/brew update"
          return [] if output.match /\aAlready up-to-date/

          extract_updated_definitions(output)
        end

        def upgrade_packages
          output = current_shell.exec "#{@bin_path}/brew upgrade"

          extract_upgraded_packages(output)
        end

        private

        # Extracts the list of updated package definitions from the output of
        # a #update_definitions call.
        #
        # @param [String] output from the #update_defintions call.
        # @return [Array<Hash{new_formulae: Array, updated_formulae: Array, deleted_formulae: Array}>]
        # TODO: How to deal with output being an Exception?
        def extract_updated_definitions(output)
          return [] unless output.is_a? String

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

          updated
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
