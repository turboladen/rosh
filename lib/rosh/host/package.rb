require_relative 'package_types/base'


class Rosh
  class Host
    class Package
      attr_reader :package_name

      def initialize(type, name, shell)
        @shell = shell
        @package_name = name
        @type = type
      end

      # Installs the package using brew and notifies observers with the new
      # version.  If a version is given and that version is already installed,
      # brew switches back to use the given version.
      #
      # @param [String] version Version of the package to install.
      # @return [Boolean] +true+ if install was successful, +false+ if not,
      #   +nil+ if no action was required.
      def install(version: nil)
        return if skip_install?(version)

        old_version = adapter.current_version
        success = adapter.install(version)
        new_version = adapter.current_version
        notify_on_success(new_version, old_version, success)

        success
      end

      # @return [Boolean] +true+ if installed; +false+ if not.
      def installed?
        adapter.installed?
      end

      # Upgrades the package, using `brew upgrade ` and updates observers with
      # the new version.
      #
      # @return [Boolean] +true+ if upgrade was successful, +false+ if not.
      def upgrade
        old_version = adapter.current_version
        success = adapter.upgrade

        # TODO: is the same as #notify_on_success?
        if success
          new_version = current_version

          if old_version != new_version
            adapter.changed
            adapter.notify_observers(adapter,
              attribute: :version, old: old_version, new: new_version,
              as_sudo: @shell.su?)
          end
        end

        success
      end

      # Removes the package using `brew remove ` and notifies observers.
      #
      # @return [Boolean] +true+ if install was successful; +false+ if not.
      def remove
        already_installed = adapter.installed?

        if @shell.check_state_first? && !already_installed
          return
        end

        old_version = adapter.current_version
        success = adapter.remove

        if success && already_installed
          adapter.changed
          adapter.notify_observers(self,
            attribute: :version, old: old_version, new: nil,
            as_sudo: @shell.su?)
        end

        success
      end

      def info
        adapter.info
      end

      def at_latest_version?
        adapter.at_latest_version?
      end

      def current_version
        adapter.current_version
      end

      #-------------------------------------------------------------------------
      # PRIVATES
      #-------------------------------------------------------------------------
      private

      # Creates the adapter if it's not yet been set.
      #
      # @return [Rosh::Host::PackageTypes::*]
      def adapter
        @adapter ||= create_adapter(@type, @package_name, @shell)
      end

      # Creates the adapter object based on the given +type+.
      #
      # @param [Symbol, String] type
      # @param [String] name
      # @param [Rosh::Host::Shells::*] shell
      #
      # @return [Rosh::Host::PackageTypes::*]
      def create_adapter(type, name, shell)
        puts "package_types/#{type}"
        require_relative "package_types/#{type}"

        package_klass = Rosh::Host::PackageTypes.
          const_get(type.to_s.capitalize.to_sym)

        package_klass.new(name, shell)
      end

      # Checks to see if installing the package should be skipped based on the
      # shell settings, if the package is installed, and which version the
      # package is at.
      def skip_install?(version=nil)
        if @shell.check_state_first? && adapter.installed?
          #log 'SKIP: check_state_first is true and already at latest version.'
          if version
            true if version == adapter.current_version
          else
            true
          end
        else
          false
        end
      end

      def notify_on_success(new_version, old_version, success)
        if success && old_version != new_version
          adapter.changed
          adapter.notify_observers(adapter,
            attribute: :version, old: old_version, new: new_version,
            as_sudo: @shell.su?)
        end
      end
    end
  end
end
