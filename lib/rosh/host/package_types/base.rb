require 'observer'
require_relative '../string_refinements'


class Rosh
  class Host
    module PackageTypes

      # Class containing the base attributes for other PackageTypes object.
      class Base
        include Observable

        attr_reader :name
        # @!attribute [r] name
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

        attr_writer :bin_path

        # @param [String] name Name of the package.
        # @param [String,Symbol] host_label
        # @param [String] version
        # @param [Symbol] status
        # @param [String] architecture
        def initialize(name, host_label,
          version: nil, status: nil, architecture: nil,
          bin_path: nil
        )
          @name = name
          @host_label = host_label
          @version = version
          @status = status
          @architecture = architecture
          @bin_path = bin_path
        end
      end
    end
  end
end
