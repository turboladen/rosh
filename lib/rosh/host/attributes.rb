require_relative 'string_refinements'


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
          redhat = false

          result = case self.operating_system
          when :linux
            r = catch(:shell_failure) do
              @shell.exec 'lsb_release --description'
            end

            unless r[:exit_status].zero?
              redhat = true
              @shell.exec 'cat /etc/redhat-release'
            end
          when :darwin
            @shell.exec 'sw_vers'
          end

          if redhat
            extract_redhat(result)
          else
            extract_distribution(result)
          end

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

      # The name of the remote shell for the user on hostname that initiated the
      # Rosh::SSH connection for the host.
      #
      # @return [String] The shell type.
      def remote_shell
        command = 'echo $SHELL'
        result = @shell.exec(command)
        stdout = result.ssh_result.stdout
        log "STDOUT: #{stdout}"
        %r[(?<shell>[a-z]+)$] =~ stdout

        shell.to_sym
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

        %r[^(?<os>[a-zA-Z]+) (?<uname>.*)] =~ result
        @operating_system = os.to_safe_down_sym

        case @operating_system
        when :darwin
          %r[Kernel Version (?<version>\d\d\.\d\d?\.\d\d?).*RELEASE_(?<arch>\S+)] =~ uname
        when :linux
          %r[\S+\s+(?<version>\S+).*\s(?<arch>\S+)\s*$] =~ uname
        when :freebsd
          %r[\S+\s+(?<version>\S+).*\s(?<arch>\S+)\s*$] =~ uname
        end

        @kernel_version = version
        @architecture = arch.downcase.to_sym
      end

      # Extracts info about the distribution.
      #
      # @param [Rosh::CommandResult] result
      # @todo What if @operating_system isn't set yet?
      def extract_distribution(result)
        stdout = result
        log "STDOUT: #{stdout}"

        case @operating_system
        when :darwin
          %r[ProductName:\s+(?<distro>[^\n]+)\s*ProductVersion:\s+(?<version>\S+)]m =~ stdout
        when :linux
          %r[Description:\s+(?<distro>\w+)\s+(?<version>[^\n]+)] =~ stdout
        end

        @distribution = distro.to_safe_down_sym
        @distribution_version = version
      end

      def extract_redhat(result)
        %r[(?<distro>\w+)\s+release\s+(?<version>[^\n]+)] =~ result

        @distribution = distro.to_safe_down_sym
        @distribution_version = version
      end
    end
  end
end
