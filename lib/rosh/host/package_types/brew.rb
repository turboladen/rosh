require_relative 'base'


class Rosh
  class Host
    module PackageTypes
      class Brew < Base

        # @param [String] name Name of the package.
        # @param [Rosh::Host::Shells::Local,Rosh::Host::Shells::Remote] shell
        #   Shell for the OS that's being managed.
        # @param [String] version
        # @param [Status] status
        # @param [Status] architecture
        def initialize(name, shell, version: nil, status: nil, architecture: nil)
          super(name, shell, version: version, status: status)
        end

        # Partial result of `brew info ` as a Hash.
        #
        # @return [Hash]
        def info
          output = @shell.exec "brew info #{@name}"
          info_hash = {}

          /^\s*#{@name}: (?<spec>\w+) (?<version>[^\n]+)
(?<home>https?:\/\/[^\n]*)/ =~ output

          info_hash[:package] = @name
          info_hash[:spec] = $~[:spec]
          info_hash[:version] = $~[:version].strip
          info_hash[:homepage] = $~[:home].strip

          info_hash
        end

        # @return [Boolean] +true+ if installed; +false+ if not.
        def installed?
          result = @shell.exec "brew info #{@name}"

          !result.match /Not installed/
        end

        # Installs the package using brew and notifies observers with the new
        # version.  If a version is given and that version is already installed,
        # brew switches back to use the given version.
        #
        # @param [String] version Version of the package to install.
        # @return [Boolean] +true+ if install was successful; +false+ if not.
        def install(version: nil)
          already_installed = installed?
          old_version = info[:version] if already_installed

          if version
            install_and_switch_version(version)
          else
            @shell.exec "brew install #{@name}"
            success = @shell.last_exit_status.zero?
            new_version = info[:version]

            if success && old_version != new_version
              changed
              notify_observers(self, attribute: :version, old: old_version,
                new: new_version)
            end

            success
          end
        end

        # Removes the package using `brew remove ` and notifies observers.
        #
        # @return [Boolean] +true+ if install was successful; +false+ if not.
        def remove
          already_installed = installed?
          old_version = info[:version] if already_installed

          @shell.exec "brew remove #{@name}"
          success = @shell.last_exit_status.zero?

          if success && already_installed
            changed
            notify_observers(self, attribute: :version, old: old_version,
              new: nil)
          end

          success
        end

        # Upgrades the package, using `brew upgrade ` and updates observers with
        # the new version.
        #
        # @return [Boolean] +true+ if upgrade was successful, +false+ if not.
        def upgrade
          old_version = info[:version]

          @shell.exec "brew upgrade #{@name}"
          success = @shell.last_exit_status.zero?

          if success
            new_version = info[:version]

            if old_version != new_version
              changed
              notify_observers(self, attribute: :version, old: old_version,
                new: new_version)
            end
          end

          success
        end

        private

        # Handles checking out appropriate git version for the package version,
        # unlinking the old version, installing the requested version, and
        # switching to the requested version.
        #
        # @param [String] version The version to install/switch to.
        # @return [Boolean] +true+ if install was successful; +false+ if not.
        def install_and_switch_version(version)
          version_line = @shell.exec("brew versions #{@name} | grep #{version}").
            split("\n").last
          return false unless version_line

          %r[git checkout (?<hash>\w+)] =~ version_line

          prefix = @shell.exec 'brew --prefix'
          @shell.cd(prefix)

          @shell.exec "git checkout #{hash} Library/Formula/#{@name}.rb"
          return false unless @shell.last_exit_status.zero?

          @shell.exec "brew unlink #{@name}"
          return false unless @shell.last_exit_status.zero?

          @shell.exec "brew install #{@name}"
          return false unless @shell.last_exit_status.zero?

          @shell.exec "brew switch #{@name} #{version}"
          return false unless @shell.last_exit_status.zero?

          @shell.exec "git checkout -- Library/Formula/#{@name}.rb"
          @shell.last_exit_status.zero?
        end

      end
    end
  end
end
