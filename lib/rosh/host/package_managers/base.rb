require 'observer'

class Rosh
  class Host
    module PackageManagers
      class Base
        include Observable

        def initialize(shell)
          @shell = shell
        end
      end
    end
  end
end
