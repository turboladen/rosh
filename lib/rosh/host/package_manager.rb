require 'observer'
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
      include Observable

      # @param [Rosh::Shell] shell
      # @param [Symbol] manager_types The PackageManager types to delegate to.
      #   Look at the list of PackageManagers.
      def initialize(shell, *manager_types)
        @shell = shell

        manager_types.each do |type|
          self.class.
            send(:prepend, Rosh::Host::PackageManagers.const_get(type.to_s.capitalize.to_sym))
        end
      end

      # Use for managing a single package.
      #
      # @param [String] package_name The package name to manage.
      # @return [Rosh::PackageType]
      def [](package_name)
        create(package_name)
      end
    end
  end
end
