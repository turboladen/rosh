require_relative '../changeable'
require_relative '../observable'


class Rosh
  class PackageManager
    class PackageNotFound < RuntimeError; end

    class Package
      include Rosh::Changeable
      include Rosh::Observable

      attr_reader :name
      # @!attribute [r] name
      #   Name of the OS package this represents.
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

      def initialize(package_name, host_name)
        @name = package_name
        @host_name = host_name
      end

      def at_latest_version?
        adapter.at_latest_version?
      end

      #   Version of the OS package this represents, if any.  Defaults to
      #   +nil+.
      #   @return [String]
      def version
        @version ||= adapter.current_version
      end

      def info
        adapter.info
      end

      # Installs the package and notifies observers with the new
      # version.
      #
      # @param [String] version Version of the package to install.
      # @return [Boolean] +true+ if install was successful, +false+ if not,
      #   +nil+ if no action was required.
      def install(version: nil)
        already_installed = self.installed?
        at_latest = self.at_latest_version?
        old_version = self.current_version

        criteria = [
          -> { !already_installed },
          -> { !at_latest }
        ]

        change_if(criteria) do
          if !already_installed
            notify_about(self, :installed, from: false, to: true) do
              adapter.install
            end
          else
            notify_about(self, :version, from: old_version, to: self.latest_version) do
              adapter.install
            end
          end
        end
      end

      def installed?
        adapter.installed?
      end

      def installed_versions
        adapter.installed_versions
      end

      def latest_version
        adapter.latest_version
      end

      def remove
        change_if(self.installed?) do
          adapter.remove

          notify_about(self, :installed, from: true, to: false) do
            adapter.installed?
          end
        end
      end

      def upgrade
        current_version = self.version

        change_if(current_version < self.latest_version) do
          adapter.upgrade
          new_version = adapter.current_version

          notify_about(self, :version, from: current_version, to: new_version) do
            current_version != new_version
          end
        end
      end

      private

      def adapter
        return @adapter if @adapter

        @adapter = case current_host.operating_system
        when :linux
          case current_host.distribution
          when :ubuntu
            require_relative 'object_adapters/deb'
            PackageManager::ObjectAdapters::Deb
          when :centos
            require_relative 'object_adapters/rpm'
            PackageManager::ObjectAdapters::Rpm
          end
        when :darwin
          require_relative 'object_adapters/brew'
          PackageManager::ObjectAdapters::Brew
        end

        @adapter.package_name = @name
        @adapter.host_name = @host_name

        @adapter
      end
    end
  end
end
