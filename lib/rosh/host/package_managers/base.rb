require 'observer'

class Rosh
  class Host
    module PackageManagers
      class Base
        include Observable

        attr_writer :bin_path

        def initialize(host_label)
          @host_label = host_label
        end
      end
    end
  end
end
