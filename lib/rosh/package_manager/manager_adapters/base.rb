class Rosh
  class PackageManager
    module ManagerAdapters
      module Base
        def self.included(base)
          base.extend ClassMethods
          Base.const_set(:DEFAULT_BIN_PATH, base.const_get(:DEFAULT_BIN_PATH))
        end

        module ClassMethods
          def bin_path
            @bin_path ||= Base::DEFAULT_BIN_PATH
          end

          def host_name=(host_name)
            @host_name = host_name
          end

          def package_name=(package_name)
            @package_name = package_name
          end
        end
      end
    end
  end
end
