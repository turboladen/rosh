require_relative 'base'


class Rosh
  class Host
    module PackageTypes

      # Represents a package in the {http://brew.sh homebrew} package manager.
      class Brew < Base

        # Install the package.  If no +version+ is given, uses the latest in
        # Brew's repo.
        #
        # @param [String] version
        # @return [Boolean] +true+ if successful, +false+ if not.
        def install(version=nil)
          if version
            install_and_switch_version(version)
          else
            @shell.exec "brew install #{@package_name}"

            @shell.last_exit_status.zero?
          end
        end

        # Uses <tt>brew info [pkg]</tt> to see if the package is installed or
        # not.
        #
        # @return [Boolean] +true+ if installed, +false+ if not.
        def installed?
          result = @shell.exec "brew info #{@package_name}"

          if @shell.last_exit_status.zero?
            !result.match %r[Not installed]
          else
            false
          end
        end

        # Uses <tt>brew upgrade [pkg]</tt> to upgrade the package.
        #
        # @return [Boolean] +true+ if successful, +false+ if not.
        def upgrade
          @shell.exec "brew upgrade #{@package_name}"

          @shell.last_exit_status.zero?
        end

        # Uses <tt>brew remove [pkg]</tt> to remove the package.
        #
        # @return [Boolean] +true+ if successful, +false+ if not.
        def remove
          @shell.exec "brew remove #{@package_name}"

          @shell.last_exit_status.zero?
        end

        # Partial result of <tt>brew info [pkg]</tt> as a Hash.
        #
        # @return [Hash]
        def info
          output = @shell.exec "brew info #{@package_name}"
          info_hash = {}

          /^\s*#{@package_name}: (?<spec>\w+) (?<version>[^\n]+)
(?<home>https?:\/\/[^\n]*)/ =~ output

          info_hash[:package] = @package_name
          info_hash[:spec] = $~[:spec]
          info_hash[:version] = $~[:version].strip
          info_hash[:homepage] = $~[:home].strip

          info_hash
        end

        # @return [Array<String>] The list of versions of the current package
        #   that are installed.
        def installed_versions
          result = @shell.exec "brew info #{@package_name}"

          result.each_line.map do |line|
            %r[.*Cellar/#{@package_name}/(?<version>\S+)] =~ line.strip
            $~ ? $~[:version] : nil
          end.compact
        end

        # @return [Boolean] Checks to see if the latest installed version is
        #   the latest version available.
        def at_latest_version?
          info[:version] == current_version
        end

        # @return [String] The currently installed version of the package. +nil+
        #   if the package is not installed.
        def current_version
          installed_versions.last
        end

        private

        # Handles checking out appropriate git version for the package version,
        # unlinking the old version, installing the requested version, and
        # switching to the requested version.
        #
        # @param [String] version The version to install/switch to.
        # @return [Boolean] +true+ if install was successful; +false+ if not.
        def install_and_switch_version(version)
          version_line = @shell.exec("brew versions #{@package_name} | grep #{version}").
            split("\n").last
          return false unless version_line

          %r[git checkout (?<hash>\w+)] =~ version_line

          prefix = @shell.exec 'brew --prefix'
          @shell.cd(prefix)

          @shell.exec "git checkout #{hash} Library/Formula/#{@package_name}.rb"
          return false unless @shell.last_exit_status.zero?

          @shell.exec "brew unlink #{@package_name}"
          return false unless @shell.last_exit_status.zero?

          @shell.exec "brew install #{@package_name}"
          return false unless @shell.last_exit_status.zero?

          @shell.exec "brew switch #{@package_name} #{version}"
          return false unless @shell.last_exit_status.zero?

          @shell.exec "git checkout -- Library/Formula/#{@package_name}.rb"

          @shell.last_exit_status.zero?
        end
      end
    end
  end
end
