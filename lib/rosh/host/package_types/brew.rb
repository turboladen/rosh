class Rosh
  class Host
    module PackageTypes

      # Represents a package in the {http://brew.sh homebrew} package manager.
      module Brew

        # Partial result of <tt>brew info [pkg]</tt> as a Hash.
        #
        # @return [Hash]
        def info
          output = current_shell.exec "#{@bin_path}/brew info #{@name}"
          info_hash = {}

          /^\s*#{@name}: (?<spec>\w+) (?<version>[^\n]+)
(?<home>https?:\/\/[^\n]*)/ =~ output

          info_hash[:package] = @name
          info_hash[:spec] = $~[:spec]
          info_hash[:version] = $~[:version].strip
          info_hash[:homepage] = $~[:home].strip

          info_hash[:status] = if output.match(/Not installed/m)
            :not_installed
          else
            :installed
          end

          info_hash
        end

        # Uses <tt>brew info [pkg]</tt> to see if the package is installed or
        # not.
        #
        # @return [Boolean] +true+ if installed, +false+ if not.
        def installed?
          result = current_shell.exec "#{@bin_path}/brew info #{@name}"

          if current_shell.last_exit_status.zero?
            !result.match %r[Not installed]
          else
            false
          end
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

        # @return [Array<String>] The list of versions of the current package
        #   that are installed.
        # TODO: This is brew-specific... what to do?
        def installed_versions
          result = current_shell.exec "#{@bin_path}/brew info #{@name}"

          result.each_line.map do |line|
            %r[.*Cellar/#{@name}/(?<version>\S+)] =~ line.strip
            $~ ? $~[:version] : nil
          end.compact
        end

        private

        def default_bin_path
          '/usr/local/bin'
        end

        # Install the package.  If no +version+ is given, uses the latest in
        # Brew's repo.
        #
        # @param [String] version
        # @return [Boolean] +true+ if successful, +false+ if not.
        def install_package(version=nil)
          if version
            install_and_switch_version(version)
          else
            current_shell.exec "#{@bin_path}/brew install #{@name}"

            current_shell.last_exit_status.zero?
          end
        end

        # Uses <tt>brew upgrade [pkg]</tt> to upgrade the package.
        #
        # @return [Boolean] +true+ if successful, +false+ if not.
        def upgrade_package
          current_shell.exec "#{@bin_path}/brew upgrade #{@name}"

          current_shell.last_exit_status.zero?
        end

        # Uses <tt>brew remove [pkg]</tt> to remove the package.
        #
        # @return [Boolean] +true+ if successful, +false+ if not.
        def remove_package
          current_shell.exec "#{@bin_path}/brew remove #{@name}"

          current_shell.last_exit_status.zero?
        end

        # Handles checking out appropriate git version for the package version,
        # unlinking the old version, installing the requested version, and
        # switching to the requested version.
        #
        # @param [String] version The version to install/switch to.
        # @return [Boolean] +true+ if install was successful; +false+ if not.
        def install_and_switch_version(version)
          version_line = current_shell.exec("#{@bin_path}/brew versions #{@name} | grep #{version}").
            split("\n").last
          return false unless version_line

          %r[git checkout (?<hash>\w+)] =~ version_line

          prefix = current_shell.exec "#{@bin_path}/brew --prefix"
          current_shell.cd(prefix)

          current_shell.exec "git checkout #{hash} Library/Formula/#{@name}.rb"
          return false unless current_shell.last_exit_status.zero?

          current_shell.exec "#{@bin_path}/brew unlink #{@name}"
          return false unless current_shell.last_exit_status.zero?

          current_shell.exec "#{@bin_path}/brew install #{@name}"
          return false unless current_shell.last_exit_status.zero?

          current_shell.exec "#{@bin_path}/brew switch #{@name} #{version}"
          return false unless current_shell.last_exit_status.zero?

          current_shell.exec "git checkout -- Library/Formula/#{@name}.rb"

          current_shell.last_exit_status.zero?
        end
      end
    end
  end
end
