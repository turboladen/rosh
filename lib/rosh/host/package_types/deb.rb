class Rosh
  class Host
    module PackageTypes

      # Represents a {https://wiki.debian.org/DebianPackage Debian package}.
      # Managed using {https://wiki.debian.org/Apt Apt} and
      # {https://wiki.debian.org/dpkg dpkg}.
      module Deb

        # Result of `dpkg --status` as a Hash.
        #
        # @return [Hash]
        def info
          output = current_shell.exec "dpkg --status #{@name}"
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

        # Uses <tt>dpkg --status [pkg]</tt> to see if the package is installed
        # or not.
        #
        # @return [Boolean] +true+ if installed, +false+ if not.
        def installed?
          current_shell.exec "dpkg --status #{@name}"

          current_shell.last_exit_status.zero?
        end

        # @return [Boolean] Checks to see if the latest installed version is
        #   the latest version available.
        def at_latest_version?
          cmd = "apt-cache policy #{@name}"
          result = current_shell.exec(cmd)
          %r[Installed: (?<current>\S+)\n\s*Candidate: (?<candidate>\S+)] =~ result

          if $~
            $~[:current] == $~[:candidate]
          end
        end

        # @return [String] The currently installed version of the package. +nil+
        #   if the package is not installed.
        def current_version
          cmd = "apt-cache policy #{@name}"
          result = current_shell.exec(cmd)
          %r[Installed: (?<version>\S*)] =~ result

          if $~
            $~[:version] == '(none)' ? nil : $~[:version]
          else
            nil
          end
        end

        private

        def default_bin_path
          '/usr/local'
        end

        # Install the package.  If no +version+ is given, uses the latest in
        # Apt's cache.
        #
        # @param [String] version
        # @return [Boolean] +true+ if successful, +false+ if not.
        def install_package(version=nil)
          cmd = "DEBIAN_FRONTEND=noninteractive apt-get install #{@name}"
          cmd << "=#{version}" if version
          cmd << ' -y'
          current_shell.exec(cmd)

          current_shell.last_exit_status.zero?
        end

        # Upgrades the package, using `apt-get install`.
        #
        # @return [Boolean] +true+ if install was successful, +false+ if not.
        def upgrade_package
          install_package
        end

        # Uses <tt>apt-get remove [pkg]</tt> to remove the package.
        #
        # @return [Boolean] +true+ if successful, +false+ if not.
        def remove_package
          current_shell.exec "DEBIAN_FRONTEND=noninteractive apt-get remove #{@name}"

          current_shell.last_exit_status.zero?
        end
      end
    end
  end
end
