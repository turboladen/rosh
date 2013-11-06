class Rosh
  class PackageManager
    module ObjectAdapters

      # Represents a {https://wiki.debian.org/DebianPackage Debian package}.
      # Managed using {https://wiki.debian.org/Apt Apt} and
      # {https://wiki.debian.org/dpkg dpkg}.
      module Deb
        DEFAULT_BIN_PATH = '/usr/local'

        # @return [Boolean] Checks to see if the latest installed version is
        #   the latest version available.
        def at_latest_version?
          cmd = "apt-cache policy #{@package_name}"
          result = current_shell.exec_internal(cmd)
          %r[Installed: (?<current>\S+)\r\n\s*Candidate: (?<candidate>\S+)] =~ result

          if $~
            $~[:current] == $~[:candidate]
          end
        end

        # @return [String] The currently installed version of the package. +nil+
        #   if the package is not installed.
        def current_version
          cmd = "apt-cache policy #{@package_name}"
          result = current_shell.exec_internal(cmd)
          %r[Installed: (?<version>\S*)] =~ result

          if $~
            $~[:version] == '(none)' ? nil : $~[:version]
          else
            nil
          end
        end

        # Result of `dpkg --status` as a Hash.
        #
        # @return [Hash]
        def info
          output = current_shell.exec_internal "dpkg --status #{@package_name}"
          info_hash = {}

          output.each_line do |line|
            %r[(?<key>.+): (?<value>[^\r\n]*)] =~ line

            if key
              info_hash[key.to_safe_down_sym] = value
            else
              last_key = info_hash.keys.last
              info_hash[last_key] << "\n#{line.strip}"
            end
          end

          info_hash
        end

        # Install the package.  If no +version+ is given, uses the latest in
        # Apt's cache.
        #
        # @param [String] version
        # @return [Boolean] +true+ if successful, +false+ if not.
        def install(version=nil)
          #cmd = "DEBIAN_FRONTEND=noninteractive apt-get install #{@package_name}"
          cmd = "apt-get install #{@package_name}"
          cmd << "=#{version}" if version
          cmd << ' -y'
          current_shell.exec_internal(cmd)

          current_shell.last_exit_status.zero?
        end

        # Uses <tt>dpkg --status [pkg]</tt> to see if the package is installed
        # or not.
        #
        # @return [Boolean] +true+ if installed, +false+ if not.
        def installed?
          output = current_shell.exec_internal "dpkg --status #{@package_name}"
          return false unless current_shell.last_exit_status.zero?

          !output.match(/not-installed/)
        end

        def installed_versions
          warn 'Not implemented!'
        end

        def latest_version
          warn 'Not implemented!'
        end

        # Uses <tt>apt-get remove [pkg]</tt> to remove the package.
        #
        # @return [Boolean] +true+ if successful, +false+ if not.
        def remove
          current_shell.exec_internal "DEBIAN_FRONTEND=noninteractive apt-get remove -y #{@package_name}"

          current_shell.last_exit_status.zero?
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
