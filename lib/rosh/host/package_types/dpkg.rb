class Rosh
  class Host
    module PackageTypes
      class Dpkg
        attr_reader :name

        def initialize(shell, name)
          @shell = shell
          @name = name
        end

        def info
          @shell.exec "dpkg -s #{@name}"
        end
      end
    end
  end
end
