class Rosh
  class Host
    module PackageTypes
      class Apt
        attr_reader :name

        def initialize(shell, name)
          @shell = shell
          @name = name
        end

        def info
          @shell.exec "apt-cache showpkg #{@name}"
        end
      end
    end
  end
end
