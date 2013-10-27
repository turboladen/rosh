class Rosh
  class PackageManager
    module ObjectAdapters

      # Represents a {http://www.rpm.org RPM package}.  Managed here using
      # {http://yum.baseurl.org Yum} and RPM commands.
      module Rpm
        DEFAULT_BIN_PATH = '/usr/bin'

        # @return [Boolean] Checks to see if the latest installed version is
        #   the latest version available.
        def at_latest_version?
          cmd = "yum list updates #{@package_name}"
          result = current_shell.exec(cmd)

          # Could be that: a) not a package, b) the package is not installed, c)
          # the package is at the latest.
          if result =~ /No matching Packages to list/
            cmd = "yum info #{@package_name}"
            result = current_shell.exec(cmd)

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

        # @return [String] The currently installed version of the package. +nil+
        #   if the package is not installed.
        def current_version
          cmd = "rpm -qa #{@package_name}"
          result = current_shell.exec(cmd)

          if result.nil? || result.empty?
            nil
          else
            %r[#{@package_name}-(?<version>\d\S*)] =~ result

            $~[:version] if $~
          end
        end

        # Result of <tt>yum info [pkg]</tt> as a Hash.
        #
        # @return [Hash]
        def info
          output = current_shell.exec "yum info #{@package_name}"
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

        # Install the package.  If no +version+ is given, uses the latest in
        # Yum's cache.
        #
        # @param [String] version
        # @return [Boolean] +true+ if successful, +false+ if not.
        def install(version=nil)
          cmd = "yum install -y #{@package_name}"
          cmd << "-#{version}" if version
          current_shell.exec(cmd)

          current_shell.last_exit_status.zero?
        end

        # Uses <tt>yum info [pkg]</tt> to see if the package is installed
        # or not.
        #
        # @return [Boolean] +true+ if installed, +false+ if not.
        def installed?
          current_shell.exec "rpm -qa | grep #{@package_name}"

          current_shell.last_exit_status.zero?
        end

        def installed_versions
          warn 'Not implemented!'
        end

        def latest_version
          warn 'Not implemented!'
        end

        # Uses <tt>yum remove [pkg]</tt> to remove the package.
        #
        # @return [Boolean] +true+ if successful, +false+ if not.
        def remove
          current_shell.exec "yum remove -y #{@package_name}"

          current_shell.last_exit_status.zero?
        end

        # Upgrades the package, using <tt>yum upgrade [pkg]</tt>.
        #
        # @return [Boolean] +true+ if install was successful, +false+ if not.
        def upgrade
          output = current_shell.exec "yum upgrade -y #{@package_name}"
          success = current_shell.last_exit_status.zero?

          return false if output.match(/#{@package_name} available, but not installed/m)
          return false if output.match(/No Packages marked for Update/m)

          success
        end
      end
    end
  end
end
