require_relative '../changeable'
require_relative '../observable'


class Rosh
  class PackageManager
    class PackageNotFound < RuntimeError; end

    class Package
      include Rosh::Changeable
      include Rosh::Observable

      def initialize(package_name, host_name)
        @name = package_name
        @host_name = host_name
      end

      def at_latest_version?
        adapter.at_latest_version?
      end

      def current_version
        adapter.current_version
      end

      def info
        adapter.info
      end

      def install
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
          notify_about(self, :installed, from: true, to: false) do
            adapter.remove
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
