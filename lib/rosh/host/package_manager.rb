require 'observer'
require_relative '../string_refinements'


class Rosh
  class Host

    # The PackageManager is the entry point for managing packages and package
    # repositories.  Calling methods on the PackageManager object operates on
    # the package repository (i.e. apt), where treating the PackageManager
    # object like a Hash where the key is a package name lets you operate on a
    # single PackageType (i.e. deb).
    #
    # For example, updating packages on Ubuntu would look like:
    #   pm = Rosh::Host::PackageManager.new(shell, :apt, :dpkg)
    #   pm.upgrade_packages
    #
    # ...installing the curl package would look like:
    #   pm['curl'].install
    #
    class PackageManager
      include Observable

      attr_writer :bin_path

      # @param [Array<Symbol>] manager_types The PackageManager types to delegate to.
      #   Look at the list of PackageManagers.
      # @param [String] host_name
      def initialize(host_name, *manager_types)
        @host_name = host_name
        manager_types.each { |manager_type| load_strategy(manager_type) }
      end

      # Use for managing a single package.
      #
      # @param [String] package_name The package name to manage.
      # @return [Rosh::Host::PackageTypes::*]
      def [](package_name)
        create_package(package_name)
      end

      def bin_path
        warn 'Not implemented!'
      end

      def installed_packages
        warn 'Not implemented!'
      end

      def update_definitions
        output = current_shell.exec(update_definitions_command)
        updated = extract_updated_definitions(output)
        success = current_shell.last_exit_status.zero?

        if success && !updated.empty?
          changed
          notify_observers(self,
            attribute: :package_definitions,
            old: [], new: updated, as_sudo: current_shell.su?)
        end

        success
      end

      # Upgrades outdated packages.  Notifies observers with packages that were
      # updated.  The list of packages in the update notification is an Array
      # of Rosh::Host::PackageTypes that are managed by the PackageManager.
      #
      # @return [Boolean] +true+ if exit status was 0; +false+ if not.
      def upgrade_packages
        old_packages = installed_packages
        output = current_shell.exec(upgrade_packages_command)
        new_packages = extract_upgraded_packages(output)
        success = current_shell.last_exit_status.zero?

        if success && !new_packages.empty?
          changed
          notify_observers(self,
            attribute: :installed_packages, old: old_packages,
            new: new_packages, as_sudo: current_shell.su?)
        end

        success
      end

      #-------------------------------------------------------------------------
      # PRIVATES
      #-------------------------------------------------------------------------
      private

      def create_package(*_)
        warn 'Not implemented!'
      end

      def update_definitions_command
        warn 'Not implemented!'
      end

      def extract_updated_definitions(*_)
        warn 'Not implemented!'
      end

      def upgrade_packages_command
        warn 'Not implemented!'
      end

      def extract_upgraded_packages(*_)
        warn 'Not implemented!'
      end

      # Mixes in the +manager_type+'s methods.
      #
      # @param [Symbol, String] manager_type
      def load_strategy(manager_type)
        require_relative "package_managers/#{manager_type}"

        package_manager_klass =
          Rosh::Host::PackageManagers.const_get(manager_type.to_s.classify)

        self.extend package_manager_klass
      end
    end
  end
end
