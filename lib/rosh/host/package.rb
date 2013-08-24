require 'observer'
require_relative '../string_refinements'


class Rosh
  class Host
    class Package
      include Observable

      attr_reader :name
      # @!attribute [r] name
      #   Name of the OS package this represents.
      #   @return [String]

      attr_reader :version
      # @!attribute [r] version
      #   Version of the OS package this represents, if any.  Defaults to
      #   +nil+.
      #   @return [String]

      attr_reader :status
      # @!attribute [r] status
      #   Status that the OS package should be in, if any.  Defaults to
      #   +nil+.
      #   @return [Symbol]

      attr_reader :architecture
      # @!attribute [r] architecture
      #   Architecture of the OS package, if any.  Defaults to +nil+.
      #   @return [Symbol]

      attr_writer :bin_path

      # @param [Symbol] type
      # @param [String] name Name of the package.
      # @param [String] host_name
      # @param [String] version
      # @param [Symbol] status
      # @param [String] architecture
      # @param [String] bin_path
      def initialize(type, name, host_name,
        version: nil, status: nil, architecture: nil,
        bin_path: nil
      )
        @host_name = host_name
        @name = name
        @type = type
        @version = version
        @status = status
        @architecture = architecture
        @bin_path = bin_path

        load_strategy(@type)
      end

      def bin_path
        @bin_path ||= default_bin_path
      end

      def info
        warn 'Not implemented! Implement in package type...'
      end

      # @return [Boolean] +true+ if installed; +false+ if not.
      def installed?
        warn 'Not implemented! Implement in package type...'
      end

      def at_latest_version?
        warn 'Not implemented! Implement in package type...'
      end

      def current_version
        warn 'Not implemented! Implement in package type...'
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

        old_version = current_version
        success = install_package(version)
        new_version = current_version
        notify_on_success(new_version, old_version, success)

        success
      end

      # Upgrades the package, using `brew upgrade ` and updates observers with
      # the new version.
      #
      # @return [Boolean] +true+ if upgrade was successful, +false+ if not.
      def upgrade
        old_version = current_version
        success = upgrade_package

        # TODO: is the same as #notify_on_success?
        if success
          new_version = current_version

          if old_version != new_version
            changed
            notify_observers(self,
              attribute: :version, old: old_version, new: new_version,
              as_sudo: current_shell.su?)
          end
        end

        success
      end

      # Removes the package using `brew remove ` and notifies observers.
      #
      # @return [Boolean] +true+ if install was successful; +false+ if not.
      def remove
        already_installed = installed?

        if current_shell.check_state_first? && !already_installed
          return
        end

        old_version = current_version
        success = remove_package

        if success && already_installed
          changed
          notify_observers(self,
            attribute: :version, old: old_version, new: nil,
            as_sudo: current_shell.su?)
        end

        success
      end

      #-------------------------------------------------------------------------
      # PRIVATES
      #-------------------------------------------------------------------------
      private

      # Loads the adapter object based on the given +type+.
      #
      # @param [Symbol, String] type
      def load_strategy(type)
        require_relative "package_types/#{type}"
        package_klass = Rosh::Host::PackageTypes.const_get(type.to_s.classify)

        extend package_klass
      end

      # Checks to see if installing the package should be skipped based on the
      # shell settings, if the package is installed, and which version the
      # package is at.
      def skip_install?(version=nil)
        if current_shell.check_state_first? && installed?
          #log 'SKIP: check_state_first is true and already at latest version.'
          if version
            true if version == current_version
          else
            true
          end
        else
          false
        end
      end

      def notify_on_success(new_version, old_version, success)
        if success && old_version != new_version
          changed
          notify_observers(self,
            attribute: :version, old: old_version, new: new_version,
            as_sudo: current_shell.su?)
        end
      end
    end
  end
end
