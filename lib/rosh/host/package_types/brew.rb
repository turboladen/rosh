class Rosh
  class Host
    module PackageTypes

      class Brew
        attr_reader :name

        def initialize(shell, name)
          @shell = shell
          @name = name
        end

        # @return [String]
        def info
          @shell.exec "brew info #{@name}"
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

        # @return [Boolean]
        def installed?
          result = @shell.exec "brew info #{@name}"

          !result.match /Not installed/
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
