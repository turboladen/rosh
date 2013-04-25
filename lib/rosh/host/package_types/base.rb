class Rosh
  class Host
    module PackageTypes
      class Base

        attr_reader :name
        attr_reader :version
        attr_reader :status

        # @param [String] name Name of the packages.
        # @param [Rosh::Host::Shells::Local,Rosh::Host::Shells::Remote] shell
        #   Shell for the OS that's being managed.
        # @param [String] version
        # @param [Status] status
        def initialize(name, shell, version: nil, status: nil)
          @name = name
          @shell = shell
          @version = version
          @status = status
        end
      end
    end
  end
end
