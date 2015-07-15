class Rosh
  class PackageManager
    module ObjectAdapters
      # Represents a package in the {http://brew.sh homebrew} package manager.
      module Brew
        DEFAULT_BIN_PATH = '/usr/local/bin'

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

        # Partial result of <tt>brew info [pkg]</tt> as a Hash.
        #
        # @return [Hash]
        def info
          output = current_shell.exec_internal "#{@bin_path}/brew info #{@package_name}"
          info_hash = {}

          /^\s*#{@package_name}: (?<spec>\w+) (?<version>[^\n]+)
(?<home>https?:\/\/[^\n]*)/ =~ output

          info_hash[:package] = @package_name
          info_hash[:spec] = $LAST_MATCH_INFO[:spec]
          info_hash[:version] = $LAST_MATCH_INFO[:version].strip
          info_hash[:homepage] = $LAST_MATCH_INFO[:home].strip

          info_hash[:status] = if output.match(/Not installed/m)
                                 :not_installed
                               else
                                 :installed
          end

          info_hash
        end

        # Installs the package using brew and notifies observers with the new
        # version.  If a version is given and that version is already installed,
        # brew switches back to use the given version.
        #
        # @param [String] version Version of the package to install.
        # @return [Boolean] +true+ if install was successful, +false+ if not,
        #   +nil+ if no action was required.
        def install(version = nil)
          if version
            install_and_switch_version(version)
          else
            current_shell.exec_internal "#{@bin_path}/brew install #{@package_name}"

            current_shell.last_exit_status.zero?
          end
        end

        # Uses <tt>brew info [pkg]</tt> to see if the package is installed or
        # not.
        #
        # @return [Boolean] +true+ if installed, +false+ if not.
        def installed?
          result = current_shell.exec_internal "#{@bin_path}/brew info #{@package_name}"

          if current_shell.last_exit_status.zero?
            !result.match /Not installed/
          else
            false
          end
        end

        # @return [Array<String>] The list of versions of the current package
        #   that are installed.
        # TODO: This is brew-specific... what to do?
        def installed_versions
          result = current_shell.exec_internal "#{@bin_path}/brew info #{@package_name}"

          result.each_line.map do |line|
            %r{.*Cellar/#{@package_name}/(?<version>\S+)} =~ line.strip
            $LAST_MATCH_INFO ? $LAST_MATCH_INFO[:version] : nil
          end.compact
        end

        def latest_version
          warn 'Not implemented!'
        end

        # Uses <tt>brew remove [pkg]</tt> to remove the package.
        #
        # @return [Boolean] +true+ if successful, +false+ if not.
        def remove
          current_shell.exec_internal "#{@bin_path}/brew remove #{@package_name}"

          current_shell.last_exit_status.zero?
        end

        # Upgrades the package, using `brew upgrade ` and updates observers with
        # the new version.
        #
        # @return [Boolean] +true+ if upgrade was successful, +false+ if not.ot.
        def upgrade
          current_shell.exec_internal "#{@bin_path}/brew upgrade #{@package_name}"

          current_shell.last_exit_status.zero?
        end

        private

        # Handles checking out appropriate git version for the package version,
        # unlinking the old version, installing the requested version, and
        # switching to the requested version.
        #
        # @param [String] version The version to install/switch to.
        # @return [Boolean] +true+ if install was successful; +false+ if not.
        def install_and_switch_version(version)
          version_line = current_shell.exec_internal("#{@bin_path}/brew versions #{@package_name} | grep #{version}").
                         split("\n").last
          return false unless version_line

          /git checkout (?<hash>\w+)/ =~ version_line

          prefix = current_shell.exec_internal "#{@bin_path}/brew --prefix"
          current_shell.cd(prefix)

          current_shell.exec_internal "git checkout #{hash} Library/Formula/#{@package_name}.rb"
          return false unless current_shell.last_exit_status.zero?

          current_shell.exec_internal "#{@bin_path}/brew unlink #{@package_name}"
          return false unless current_shell.last_exit_status.zero?

          current_shell.exec_internal "#{@bin_path}/brew install #{@package_name}"
          return false unless current_shell.last_exit_status.zero?

          current_shell.exec_internal "#{@bin_path}/brew switch #{@package_name} #{version}"
          return false unless current_shell.last_exit_status.zero?

          current_shell.exec_internal "git checkout -- Library/Formula/#{@package_name}.rb"

          current_shell.last_exit_status.zero?
        end
      end
    end
  end
end
