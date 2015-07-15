class Rosh
  class Host
    module Attributes

      @kernel_version = nil
      @architecture = nil

      @distribution = nil
      @distribution_version = nil

      @remote_shell = nil

      DISTRIBUTION_METHODS = %i[distribution distribution_version]

      DISTRIBUTION_METHODS.each do |meth|
        define_method(meth) do
          distro, version = case self.operating_system
          when :linux
            extract_linux_distribution
          when :darwin
            extract_darwin_distribution
          end

          @distribution = distro
          @distribution_version = version.strip

          instance_variable_get("@#{meth}".to_sym)
        end
      end

      # @return [Symbol]
      def operating_system
        return @operating_system if @operating_system

        command = 'uname -a'
        result = @shell.exec(command)
        extract_os(result)

        @operating_system
      end

      # @return [String]
      def kernel_version
        command = 'uname -a'
        result = @shell.exec(command)
        extract_os(result)

        @kernel_version
      end

      # @return [Symbol]
      def architecture
        return @architecture if @architecture

        command = 'uname -a'
        result = @shell.exec(command)
        extract_os(result)

        @architecture
      end

      # The name of the remote shell for the user on host_name that initiated the
      # Rosh::SSH connection for the host.
      #
      # @return [String] The shell type.
      def remote_shell
        command = 'echo $SHELL'
        result = @shell.exec(command)
        stdout = result.stdout
        log "STDOUT: #{stdout}"
        %r[(?<shell>[a-z]+)$] =~ stdout

        shell.to_sym
      end

      def darwin?
        operating_system == :darwin
      end

      def linux?
        operating_system == :linux
      end

      #---------------------------------------------------------------------------
      # Privates
      #---------------------------------------------------------------------------
      private

      # Extracts info about the operating system based on uname info.
      #
      # @param [Rosh::CommandResult] result The result of the `uname -a`
      #   command.
      def extract_os(result)
        log "STDOUT: #{result}"

        %r[^(?<os>[a-zA-Z]+) (?<uname>[^\n]*)] =~ result.strip
        @operating_system = os.to_safe_down_sym

        case @operating_system
        when :darwin
          %r[Kernel Version (?<version>\d\d\.\d\d?\.\d\d?).*RELEASE_(?<arch>\S+)] =~ uname
        when :linux
          %r[\S+\s+(?<version>\S+).*\s(?<arch>(x86_64|i386|i586|i686)).*$] =~ uname
        when :freebsd
          %r[\S+\s+(?<version>\S+).*\s(?<arch>\S+)\s*$] =~ uname
        end

        @kernel_version = version
        @architecture = arch.downcase.to_sym
      end

      # Extracts info about the distribution.
      def extract_linux_distribution
        distro, version = catch(:distro_info) do
          stdout = @shell.exec('lsb_release --description')
          %r[Description:\s+(?<distro>\w+)\s+(?<version>[^\n]+)] =~ stdout
          throw(:distro_info, [distro, version]) if distro && version

          stdout = @shell.exec('cat /etc/redhat-release')
          %r[(?<distro>\w+)\s+release\s+(?<version>[^\n]+)] =~ stdout
          throw(:distro_info, [distro, version]) if distro && version

          stdout = @shell.exec('cat /etc/slackware-release')
          %r[(?<distro>\w+)\s+release\s+(?<version>[^\n]+)] =~ stdout
          throw(:distro_info, [distro, version]) if distro && version

          stdout = @shell.exec('cat /etc/gentoo-release')
          %r[(?<distro>\S+).+release\s+(?<version>[^\n]+)] =~ stdout
          throw(:distro_info, [distro, version]) if distro && version
        end

        [distro.to_safe_down_sym, version]
      end

      def extract_darwin_distribution
        stdout = @shell.exec 'sw_vers'
        %r[ProductName:\s+(?<distro>[^\n]+)\s*ProductVersion:\s+(?<version>\S+)]m =~ stdout

        [distro.to_safe_down_sym, version]
      end
    end
  end
end
