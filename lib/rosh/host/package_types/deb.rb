require_relative 'base'


class Rosh
  class Host
    module PackageTypes

      # Represents a {https://wiki.debian.org/DebianPackage Debian package}.
      # Managed using {https://wiki.debian.org/Apt Apt} and
      # {https://wiki.debian.org/dpkg dpkg}.
      class Deb < Base

        # Install the package.  If no +version+ is given, uses the latest in
        # Apt's cache.
        #
        # @param [String] version
        # @return [Boolean] +true+ if successful, +false+ if not.
        def install(version=nil)
          cmd = "DEBIAN_FRONTEND=noninteractive apt-get install #{@name}"
          cmd << "=#{version}" if version
          cmd << ' -y'
          @shell.exec(cmd)

          @shell.last_exit_status.zero?
        end

        # Uses <tt>dpkg --status [pkg]</tt> to see if the package is installed
        # or not.
        #
        # @return [Boolean] +true+ if installed, +false+ if not.
        def installed?
          @shell.exec "dpkg --status #{@name}"

          @shell.last_exit_status.zero?
        end

        # Upgrades the package, using `apt-get install`.
        #
        # @return [Boolean] +true+ if install was successful, +false+ if not.
        def upgrade
          install
        end

        # Uses <tt>apt-get remove [pkg]</tt> to remove the package.
        #
        # @return [Boolean] +true+ if successful, +false+ if not.
        def remove
          @shell.exec "DEBIAN_FRONTEND=noninteractive apt-get remove #{@name}"

          @shell.last_exit_status.zero?
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

        # @return [Boolean] Checks to see if the latest installed version is
        #   the latest version available.
        def at_latest_version?
          cmd = "apt-cache policy #{@name}"
          result = @shell.exec(cmd)
          %r[Installed: (?<current>\S+)\n\s*Candidate: (?<candidate>\S+)] =~ result

          if $~
            $~[:current] == $~[:candidate]
          end
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
      end
    end
  end
end
