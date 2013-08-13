require_relative 'base'


class Rosh
  class Host
    module PackageTypes
      class Rpm < Base

        def install(version=nil)
          cmd = "yum install -y #{@package_name}"
          cmd << "-#{version}" if version
          @shell.exec(cmd)

          @shell.last_exit_status.zero?
        end

        def installed?
          @shell.exec "yum info #{@package_name}"

          @shell.last_exit_status.zero?
        end

        # Upgrades the package, using `yum upgrade`.
        #
        # @return [Boolean] +true+ if install was successful, +false+ if not.
        def upgrade
          output = @shell.exec "yum upgrade -y #{@package_name}"
          success = @shell.last_exit_status.zero?

          return false if output.match(/#{@package_name} available, but not installed/m)
          return false if output.match(/No Packages marked for Update/m)

          success
        end

        def remove
          @shell.exec "yum remove -y #{@package_name}"

          @shell.last_exit_status.zero?
        end

        # Result of `yum info ` as a Hash.
        #
        # @return [Hash]
        def info
          output = @shell.exec "yum info #{@package_name}"
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

        # @return [Boolean] Checks to see if the latest installed version is
        #   the latest version available.
        def at_latest_version?
          cmd = "yum list updates #{@package_name}"
          result = @shell.exec(cmd)

          # Could be that: a) not a package, b) the package is not installed, c)
          # the package is at the latest.
          if result =~ /No matching Packages to list/
            cmd = "yum info #{@package_name}"
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

        # @return [String] The currently installed version of the package. +nil+
        #   if the package is not installed.
        def current_version
          cmd = "rpm -qa #{@package_name}"
          result = @shell.exec(cmd)

          if result.empty?
            nil
          else
            %r[#{@package_name}-(?<version>\d\S*)] =~ result

            $~[:version] if $~
          end
        end
      end
    end
  end
end
