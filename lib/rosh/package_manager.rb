require_relative 'observable'
require_relative 'observer'
require_relative 'changeable'
require_relative 'package_manager/package'
require_relative 'package_manager/manager_adapter'

class Rosh
  # The PackageManager is the entry point for managing packages and package
  # repositories.  Calling methods on the PackageManager object operates on
  # the package repository (i.e. apt), where treating the PackageManager
  # object like a Hash where the key is a package name lets you operate on a
  # single PackageType (i.e. deb).
  #
  # For example, updating packages on Ubuntu would look like:
  #   pm = Rosh::PackageManager.new(host_name)
  #   pm.upgrade_packages
  #
  # ...installing the curl package would look like:
  #   pm['curl'].install
  #
  class PackageManager
    include Rosh::Changeable
    include Rosh::Observer
    include Rosh::Observable

    def initialize(host_name)
      @host_name = host_name
    end

    def [](name)
      result = package(name)
      result.add_observer(self)

      result
    end

    def installed_packages
      echo_rosh_command

      adapter.installed_packages
    end

    def package(name)
      Rosh::PackageManager::Package.new(name, @host_name)
    end

    def update_definitions
      echo_rosh_command

      change_if(true) do
        updated_packages = adapter.update_definitions
        success = current_shell.last_exit_status.zero?

        notify_about(self, :package_definitions, from: '?', to: updated_packages, criteria: success) do
          updated_packages
        end
      end
    end

    # @todo Use criteria for change
    def upgrade_packages
      echo_rosh_command

      old_packages = installed_packages

      change_if(true) do
        upgraded_packages = adapter.upgrade_packages
        success = current_shell.last_exit_status.zero?

        upgraded_packages.each do |upgraded_package|
          old_package = old_packages.find { |pkg| pkg.name == upgraded_package.name }

          notify_about(upgraded_package, :package_version, from: old_package.version, to: upgraded_package.version, criteria: success) do
            upgraded_packages
          end
        end
      end
    end

    private

    def adapter
      return @adapter if @adapter

      type = case current_host.operating_system
      when :darwin
        :brew
      when :linux
        case current_host.distribution
        when :ubuntu, :debian
          :apt
        when :centos
          :yum
        end
      end

      @adapter = PackageManager::ManagerAdapter.new(type, @host_name)
    end
  end
end
