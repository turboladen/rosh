require 'etc'
require 'socket'
require 'log_switch'
require_relative 'local_shell'
require_relative 'local_file_system'
require_relative 'remote_shell'
require_relative 'remote_file_system'
require_relative 'string_refinements'


class Rosh
  class Host
    extend LogSwitch
    include LogSwitch::Mixin

    UNAME_METHODS = %i[operating_system kernel_version architecture]
    DISTRIBUTION_METHODS = %i[distribution distribution_version]

    UNAME_METHODS.each do |meth|
      define_method(meth) do
        command = 'uname -a'
        result = @shell.exec(command)
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

        result = @shell.exec(command)
        extract_distribution(result)

        instance_variable_get("@#{meth}".to_sym)
      end
    end

    attr_reader :hostname
    attr_reader :shell
    attr_reader :user

    def initialize(hostname, **ssh_options)
      @hostname = hostname
      @user = ssh_options[:user] || Etc.getlogin

      @shell = if local?
        Rosh::LocalShell.new
      else
        Rosh::RemoteShell.new(@hostname, ssh_options)
      end

      @operating_system = nil
      @kernel_version = nil
      @architecture = nil

      @distribution = nil
      @distribution_version = nil

      @remote_shell = nil
    end

    def set(**ssh_options)
      @shell.set(ssh_options)
    end

    def fs
      return @fs if @fs

      @fs = if local?
        Rosh::LocalFileSystem.new
      else
        Rosh::RemoteFileSystem.new(@shell)
      end
    end

    def local?
      @hostname == 'localhost'
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
      log "STDOUT: #{result.ssh_result.stdout}"
      return nil if result.ssh_result.stdout.empty?

      %r[^(?<os>[a-zA-Z]+) (?<uname>.*)] =~ result.ssh_result.stdout
      @operating_system = os.to_safe_down_sym

      case @operating_system
      when :darwin
        %r[Kernel Version (?<version>\d\d\.\d\d?\.\d\d?).*RELEASE_(?<arch>\S+)] =~ uname
      when :linux
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
      stdout = result.ssh_result.stdout
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
  end
end
