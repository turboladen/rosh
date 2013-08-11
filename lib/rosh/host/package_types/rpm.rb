require_relative 'base'


class Rosh
  class Host
    module PackageTypes
      class Rpm < Base

        # @param [String] name Name of the package.
        # @param [Rosh::Host::Shells::Local,Rosh::Host::Shells::Remote] shell
        #   Shell for the OS that's being managed.
        # @param [String] version
        # @param [Status] status
        def initialize(name, shell, version: nil, status: nil, architecture: nil)
          super(name, shell, version: version, status: status, architecture: architecture)
        end

        # Result of `yum info ` as a Hash.
        #
        # @return [Hash]
        def info
          output = @shell.exec "yum info #{@name}"
          info_hash = {}

          output.each_line do |line|
            %r[^(?<key>.*)\s*: (?<value>[^\n]*)\n$] =~ line

            if key && !key.strip.empty?
              info_hash[key.strip.to_safe_down_sym] = value.strip
            elsif value
              last_key = info_hash.keys.last
              info_hash[last_key] << " #{value.strip}"
            end
          end

          info_hash
        end

        # @return [Boolean] +true+ if installed; +false+ if not.
        def installed?
          @shell.exec "yum info #{@name}"

          @shell.last_exit_status.zero?
        end

        # Installs the package using yum and notifies observers with the new
        # version.
        #
        # @param [String] version Version of the package to install.
        # @return [Boolean] +true+ if install was successful, +false+ if not.
        def install(version: nil)
          already_installed = installed?

          cmd = "yum install -y #{@name}"
          cmd << "-#{version}" if version

          @shell.exec(cmd)

          success = @shell.last_exit_status.zero?

          if success && !already_installed
            changed
            notify_observers(self,
              attribute: :version, old: nil, new: info[:version],
              as_sudo: @shell.su?)
          end

          success
        end

        # @return [Boolean] Checks to see if the latest installed version is
        #   the latest version available.
        def at_latest_version?
          cmd = "yum list updates #{@name}"
          result = @shell.exec(cmd)

          # Could be that: a) not a package, b) the package is not installed, c)
          # the package is at the latest.
          if result =~ /No matching Packages to list/
            cmd = "yum info #{@name}"
            result = @shell.exec(cmd)

            if result =~ /Available Packages/m
              false
            elsif result =~ %r[Installed Packages]
              true
            else
              nil
            end
          else
            if result =~ /updates/m
              false
            end
          end
        end

        # Removes the package using yum and notifies observers.
        #
        # @return [Boolean] +true+ if install was successful, +false+ if not.
        def remove
          already_installed = installed?
          old_version = info[:version] if already_installed

          @shell.exec "yum remove -y #{@name}"
          success = @shell.last_exit_status.zero?

          if success && already_installed
            changed
            notify_observers(self,
              attribute: :version, old: old_version, new: nil,
              as_sudo: @shell.su?)
          end

          success
        end

        # Upgrades the package, using `yum upgrade`.
        #
        # @return [Boolean] +true+ if install was successful, +false+ if not.
        def upgrade
          already_installed = installed?
          old_version = info[:version] if already_installed

          output = @shell.exec "yum upgrade -y #{@name}"
          success = @shell.last_exit_status.zero?

          return false if output.match(/#{@name} available, but not installed/m)
          return false if output.match(/No Packages marked for Update/m)

          if success && already_installed
            new_version = info[:version]
            changed
            notify_observers(self,
              attribute: :version, old: old_version, new: new_version,
              as_sudo: @shell.su?)
          end

          success
        end
      end
    end
  end
end
