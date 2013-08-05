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
          super(name, shell, version: version, status: status,
            architecture: architecture)
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

        # @return [Boolean] +true+ if installed; +false+ if not.
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

          cmd = "DEBIAN_FRONTEND=noninteractive apt-get install #{@name}"
          cmd << "=#{version}" if version
          cmd << ' -y'

          @shell.exec(cmd)
          success = @shell.last_exit_status.zero?
          new_version = info[:version]

          if success && old_version != new_version
            changed
            notify_observers(self,
              attribute: :version, old: old_version, new: new_version,
              as_sudo: @shell.su?)
          end

          success
        end

        # @return [String] The currently installed version of the package. +nil+
        #   if the package is not installed.
        def current_version
          cmd = "apt-cache policy #{@name}"
          result = @shell.exec(cmd)
          %r[Installed: (?<version>\S*)] =~ result

          if $~
            $~[:version] == '(none)' ? nil : $~[:version]
          else
            nil
          end
        end

        # Removes the package using apt-get and notifies observers.
        #
        # @return [Boolean] +true+ if install was successful, +false+ if not.
        def remove
          already_installed = installed?
          old_version = info[:version] if already_installed

          @shell.exec "DEBIAN_FRONTEND=noninteractive apt-get remove #{@name}"
          success = @shell.last_exit_status.zero?

          if success && already_installed
            changed
            notify_observers(self,
              attribute: :version, old: old_version, new: nil,
              as_sudo: @shell.su?)
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
