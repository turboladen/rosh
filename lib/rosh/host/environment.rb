#require_relative '../logger'
#require_relative '../environment'
require_relative 'string_refinements'

#using Rosh::StringRefinements

class Rosh
  class Host

    # Environment info for the host identified by +hostname+ at initialization.
    # This assumes that a Rosh::Host has already been initialized and added
    # to Rosh::Environment.hosts.  This uses the Rosh::SSH object
    # associated with that Host, and thus some info is related to the user that
    # was used to initiate the SSH session (i.e. #shell).
    class Environment
      extend LogSwitch
      include LogSwitch::Mixin

      UNAME_METHODS = %i[operating_system kernel_version architecture]
      DISTRIBUTION_METHODS = %i[distribution distribution_version]

      UNAME_METHODS.each do |meth|
        define_method(meth) do
          command = 'uname -a'
          result = Rosh::Environment.hosts[@ssh_hostname].ssh.run(command)
          extract_os(result)

          instance_variable_get("@#{meth}".to_sym)
        end
      end

      DISTRIBUTION_METHODS.each do |meth|
        define_method(meth) do
          command = case self.operating_system
          when :linux
            'lsb_release --description'
          when :darwin
            'sw_vers'
          end

          result = Rosh::Environment.hosts[@ssh_hostname].ssh.run(command)
          extract_distribution(result)

          instance_variable_get("@#{meth}".to_sym)
        end
      end

      # @return [String] The hostname for which to get environment info for.
      attr_reader :ssh_hostname

      # @param [String] ssh_hostname The hostname for which to get environment
      #   info for.
      def initialize(ssh_hostname)
        @ssh_hostname = ssh_hostname

        @operating_system = nil
        @kernel_version = nil
        @architecture = nil

        @distribution = nil
        @distribution_version = nil

        @shell = nil
      end

      # The name of the remote shell for the user on hostname that initiated the
      # Rosh::SSH connection for the host.
      #
      # @return [String] The shell type.
      def shell
        command = 'echo $SHELL'
        result = Rosh::Environment.hosts[@ssh_hostname].ssh.run(command)
        log "STDOUT: #{result.stdout}"
        %r[(?<shell>[a-z]+)$] =~ result.stdout

        shell.to_sym
      end

      private

      # Extracts info about the operating system based on uname info.
      #
      # @param [Rosh::ActionResult] result The result of the `uname -a`
      #   command.
      def extract_os(result)
        log "STDOUT: #{result.stdout}"
        return nil if result.stdout.empty?

        %r[^(?<os>[a-zA-Z]+) (?<uname>.*)] =~ result.stdout
        @operating_system = os.to_safe_down_sym

        case @operating_system
        when :darwin
          %r[Kernel Version (?<version>\d\d\.\d\d?\.\d\d?).*RELEASE_(?<arch>\S+)] =~ uname
        when :linux
          %r[\S+\s+(?<version>\S+).*\s(?<arch>\S+)\s*$] =~ uname
        end

        @kernel_version = version
        @architecture = arch
      end

      # Extracts info about the distribution.
      #
      # @param [Rosh::ActionResult] result
      # @todo What if @operating_system isn't set yet?
      def extract_distribution(result)
        log "STDOUT: #{result.stdout}"

        case @operating_system
        when :darwin
          %r[ProductName:\s+(?<distro>[^\n]+)\s*ProductVersion:\s+(?<version>\S+)]m =~ result.stdout
        when :linux
          %r[Description:\s+(?<distro>\w+)\s+(?<version>[^\n]+)] =~ result.stdout
        end

        @distribution = distro.to_safe_down_sym
        @distribution_version = version
      end
    end
  end
end
