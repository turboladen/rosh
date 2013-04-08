require 'etc'
require 'socket'
require 'log_switch'
require_relative 'host/attributes'
require_relative 'local_shell'
require_relative 'local_file_system'
require_relative 'remote_shell'
require_relative 'remote_file_system'


class Rosh
  class Host
    extend LogSwitch
    include LogSwitch::Mixin
    include Host::Attributes

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
  end
end
