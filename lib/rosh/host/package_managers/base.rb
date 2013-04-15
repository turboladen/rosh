class Rosh
  class Host
    module PackageManagers
      class Base
        def initialize(shell)
          @shell = shell
        end

        def [](package_name)
          create(package_name)
        end
      end
    end
  end
end
