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
          info_hash[:version] = $~[:version]
          info_hash[:homepage] = $~[:home]

          info_hash
        end

        # @return [Boolean] +true+ if installed; +false+ if not.
        def installed?
          result = @shell.exec "brew info #{@name}"

          !result.match /Not installed/
        end

        # @return [Boolean] +true+ if install was successful; +false+ if not.
        def install(version: nil)
          result = if version
            version_line = @shell.exec("brew versions #{@name} | grep #{version}").
              split("\n").last
            @shell.cd `brew --prefix`
            %r[git checkout (?<hash>\w+)] =~ version_line

            @shell.exec "git checkout #{hash} Library/Formula/#{@name}.rb"
            @shell.exec "brew unlink #{@name}"
            @shell.exec "brew install #{@name}"
            @shell.exec "brew switch #{@name} #{version}"
            @shell.exec "git checkout -- Library/Formula/#{@name}.rb"

            @shell.history.last[:exit_status]
          else
            if installed?
              0
            else
              @shell.exec "brew install #{@name}"
            end
          end

          result.zero?
        end

        # @param [Boolean] force
        def remove(force: false)
          cmd = "brew remove #{@name}"
          cmd << ' --force' if force
          @shell.exec(cmd)

          @shell.history.last[:exit_status].zero?
        end
      end
    end
  end
end
