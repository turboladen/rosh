require_relative 'base'


class Rosh
  class Host
    module PackageTypes
      class Deb < Base

        # @param [String] name Name of the package.
        # @param [Rosh::Host::Shells::Local,Rosh::Host::Shells::Remote] shell
        #   Shell for the OS that's being managed.
        # @param [String] version
        # @param [Status] status
        # @param [Status] architecture
        def initialize(name, shell, version: nil, status: nil, architecture: nil)
          super(name, shell, version: version, status: status)
        end

        # Result of `dpkg --status` as a Hash.
        #
        # @return [Hash]
        def info
          output = @shell.exec "dpkg --status #{@name}"
          info_hash = {}

          output.each_line do |line|
            %r[(?<key>.+): (?<value>[^\n]*)] =~ line

            if key
              info_hash[key.to_safe_down_sym] = value
            else
              last_key = info_hash.keys.last
              info_hash[last_key] << "\n#{line.strip}"
            end
          end

          info_hash
        end

        # @return [Boolean] +true+ if installed; +false if not.
        def installed?
          @shell.exec "dpkg --status #{@name}"

          @shell.last_exit_status.zero?
        end

        # Installs the package using apt-get and notifies observers with the new
        # version.
        #
        # @param [String] version Version of the package to install.
        # @return [Boolean] +true+ if install was successful, +false+ if not.
        def install(version: nil)
          already_installed = installed?
          old_version = info[:version] if already_installed

          cmd = "apt-get install #{@name}"
          cmd << "=#{version}" if version

          @shell.exec(cmd)
          success = @shell.last_exit_status.zero?
          new_version = info[:version]
          puts "new version: #{new_version}"

          if success && old_version != new_version
            changed
            notify_observers(self, attribute: :version, old: old_version,
              new: new_version)
          end

          success
        end

        # Removes the package using apt-get and notifies observers.
        #
        # @return [Boolean] +true+ if install was successful, +false+ if not.
        def remove
          already_installed = installed?
          old_version = info[:version] if already_installed

          @shell.exec "apt-get remove #{@name}"
          success = @shell.last_exit_status.zero?

          if success && already_installed
            changed
            notify_observers(self, attribute: :version, old: old_version,
              new: nil)
          end

          success
        end

        # Upgrades the package, using `apt-get install`.
        #
        # @return [Boolean] +true+ if install was successful, +false+ if not.
        def upgrade
          install
        end
      end
    end
  end
end
