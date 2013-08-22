Dir[File.dirname(__FILE__) + '/package_managers/*.rb'].each(&method(:require))
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

      # @param [Symbol] manager_type The PackageManager types to delegate to.
      #   Look at the list of PackageManagers.
      # @param [Symbol] package_type The PackageType to delegate to.
      #   Look at the list of PackageTypes.
      # @param [String,Symbol] host_label
      def initialize(manager_type, package_type, host_label)
        @host_label = host_label
        @manager_type = manager_type
        @package_type = package_type
      end

      # Use for managing a single package.
      #
      # @param [String] package_name The package name to manage.
      # @return [Rosh::Host::PackageTypes::*]
      def [](package_name)
        adapter.create_package(package_name)
      end

      # The directory the package manager's executable is in.
      #
      # @return [String]
      def bin_path
        adapter.bin_path
      end

      # Set the directory the package manager's executable is in.
      #
      # @param [String] new_path
      def bin_path=(new_path)
        adapter.bin_path = new_path
      end

      def installed_packages
        adapter.installed_packages
      end

      def update_definitions
        output = adapter.update_definitions
        updated = adapter._extract_updated_definitions(output)
        success = current_shell.last_exit_status.zero?

        if success && !updated.empty?
          adapter.changed
          adapter.notify_observers(adapter,
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
        old_packages = adapter.installed_packages
        output = adapter.upgrade_packages
        new_packages = adapter._extract_upgraded_packages(output)
        success = current_shell.last_exit_status.zero?

        if success && !new_packages.empty?
          adapter.changed
          adapter.notify_observers(adapter,
            attribute: :installed_packages, old: old_packages,
            new: new_packages, as_sudo: current_shell.su?)
        end

        success
      end

      #-------------------------------------------------------------------------
      # PRIVATES
      #-------------------------------------------------------------------------
      private

      # Creates the adapter if it's not yet been set.
      #
      # @return [Rosh::Host::PackageManagers::*]
      def adapter
        @adapter ||= create_adapter(@manager_type, @host_label)
      end

      # Creates the adapter object based on the given +manager_type+.
      #
      # @param [Symbol, String] manager_type
      # @param [String,Symbol] host_label
      #
      # @return [Rosh::Host::PackageManagers::*]
      def create_adapter(manager_type, host_label)
        require_relative "package_managers/#{manager_type}"

        package_manager_klass =
          Rosh::Host::PackageManagers.const_get(manager_type.to_s.classify)

        package_manager_klass.new(host_label)
      end
    end
  end
end
