require 'etc'
require 'socket'
require_relative 'local_shell'
require_relative 'remote_shell'


class Rosh
  class Host
    attr_reader :hostname
    attr_reader :shell
    attr_reader :user

    def initialize(hostname, **ssh_options)
      @hostname = hostname
      @user = ssh_options[:user] || Etc.getlogin

      @shell = if hostname == 'localhost'
        Rosh::LocalShell.new
      else
        Rosh::RemoteShell.new(@hostname, ssh_options)
      end
    end

    def set(**ssh_options)
      @shell.set(ssh_options)
    end
  end
end
