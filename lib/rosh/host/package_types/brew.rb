class Rosh
  class Host
    module PackageTypes
      class Brew
        def initialize(shell, name)
          @shell = shell
          @name = name
        end

        def info
          result = @shell.exec "brew info #{@name}"
        end
      end
    end
  end
end
