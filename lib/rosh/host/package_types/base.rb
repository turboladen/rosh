require 'observer'
require_relative '../string_refinements'


class Rosh
  class Host
    module PackageTypes
      class Base
        include Observable

        attr_reader :name
        attr_reader :version
        attr_reader :status

        # @param [String] name Name of the package.
        # @param [Rosh::Host::Shells::Local,Rosh::Host::Shells::Remote] shell
        #   Shell for the OS that's being managed.
        # @param [String] version
        # @param [Status] status
        def initialize(name, shell, version: nil, status: nil, architecture: nil)
          @name = name
          @shell = shell
          @version = version
          @status = status
          @architecture = architecture
        end

        protected

        # Checks to see if installing the package should be skipped based on the
        # shell settings, if the package is installed, and which version the
        # package is at.
        def skip_install?(version=nil)
          if @shell.check_state_first? && installed?
            #log 'SKIP: check_state_first is true and already at latest version.'
            if version
              true if version == current_version
            else
              true
            end
          else
            false
          end
        end
      end
    end
  end
end
