Dir[File.dirname(__FILE__) + '/package_managers/*.rb'].each(&method(:require))


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
      # @param [Rosh::Host::Shells::*] shell
      def initialize(manager_type, package_type, shell)
        @shell = shell
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

      def update_index
        adapter.update_index
      end

      # Upgrades outdated packages.  Notifies observers with packages that were
      # updated.  The list of packages in the update notification is an Array
      # of Rosh::Host::PackageTypes that are managed by the PackageManager.
      #
      # @return [Boolean] +true+ if exit status was 0; +false+ if not.
      def upgrade_packages
        old_packages = adapter.installed_packages
        output = adapter.upgrade_packages
        new_packages = adapter.extract_upgraded_packages(output)
        success = @shell.last_exit_status.zero?

        if success && !new_packages.empty?
          adapter.changed
          adapter.notify_observers(adapter,
            attribute: :installed_packages, old: old_packages,
            new: new_packages, as_sudo: @shell.su?)
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
        @adapter ||= create_adapter(@manager_type, @shell)
      end

      # Creates the adapter object based on the given +manager_type+.
      #
      # @param [Symbol, String] manager_type
      # @param [Rosh::Host::Shells::*] shell
      #
      # @return [Rosh::Host::PackageManagers::*]
      def create_adapter(manager_type, shell)
        require_relative "package_managers/#{manager_type}"

        package_manager_klass =
          Rosh::Host::PackageManagers.const_get(manager_type.to_s.capitalize.to_sym)

        package_manager_klass.new(shell)
      end
    end
  end
end
