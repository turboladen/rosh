require 'observer'
require_relative '../string_refinements'


class Rosh
  class Host
    module PackageTypes

      # Class containing the base attributes for other PackageTypes object.
      class Base
        include Observable

        attr_reader :package_name
        # @!attribute [r] package_name
        #   Name of the OS package this represents.
        #   @return [String]

        attr_reader :version
        # @!attribute [r] version
        #   Version of the OS package this represents, if any.  Defaults to
        #   +nil+.
        #   @return [String]

        attr_reader :status
        # @!attribute [r] status
        #   Status that the OS package should be in, if any.  Defaults to
        #   +nil+.
        #   @return [Symbol]

        attr_reader :architecture
        # @!attribute [r] architecture
        #   Architecture of the OS package, if any.  Defaults to +nil+.
        #   @return [Symbol]

        # @param [String] name Name of the package.
        # @param [Rosh::Host::Shells::*] shell
        #   Shell for the OS that's being managed.
        # @param [String] version
        # @param [Symbol] status
        # @param [String] architecture
        def initialize(name, shell, version: nil, status: nil, architecture: nil)
          @package_name = name
          @shell = shell
          @version = version
          @status = status
          @architecture = architecture
        end
      end
    end
  end
end
