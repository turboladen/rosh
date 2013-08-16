require 'observer'

class Rosh
  class Host
    module PackageManagers
      class Base
        include Observable

        attr_writer :bin_path

        def initialize(shell)
          @shell = shell
        end
      end
    end
  end
end
