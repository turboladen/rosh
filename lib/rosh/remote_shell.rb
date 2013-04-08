require 'etc'
require 'colorize'
require 'net/ssh/simple'
require 'highline/import'
require 'log_switch'
require_relative 'command_result'
require_relative 'remote_file_system_object'
require_relative 'remote_dir'
require_relative 'remote_proc_table'
require_relative 'errors'


class Rosh


  # Wrapper for Net::SSH::Simple to allow for a) not having to pass in the
  # hostname with every SSH call, and b) handle STDOUT and STDERR the same way
  # across SSH builtin_commands.
  #
  # Any options passed in to #initialize or set using #set will be used with
  # subsequent #run or #upload commands.
  #
  # Example use:
  #   ssh = Rosh::SSH.new '10.0.0.1', keys: [Dir.home + '/.ssh/keyfile'], port: 2222
  #   ssh.options     # => { :keys=>["/Users/me/.ssh/keyfile"], :port=>2222, :user=>"me", :timeout=>1800 }
  #   ssh.upload 'pretty_picture.jpg', '/var/www/pretty_things/current/images/'
  #   ssh.set user: 'deploy'
  #   ssh.unset :keys
  #   ssh.run 'touch /var/www/pretty_things/current/tmp/restart.txt'
  #
  class RemoteShell
    extend LogSwitch
    include LogSwitch::Mixin

    DEFAULT_USER = Etc.getlogin
    DEFAULT_TIMEOUT = 1800

    # @return [Hash] The Net::SSH::Simple options that were during initialization
    #   and via #set.
    attr_reader :options

    attr_reader :hostname

    attr_reader :last_result

    # @param [String] hostname Name or IP of the host to SSH in to.
    # @param [Hash] options Net::SSH::Simple options.
    def initialize(hostname, **options)
      @hostname = hostname
      @options = options

      @options[:user] = DEFAULT_USER unless @options.has_key? :user
      @options[:timeout] = DEFAULT_TIMEOUT unless @options.has_key? :timeout
      @ssh = Net::SSH::Simple.new(@options)

      @internal_pwd = nil
      @last_result = Rosh::CommandResult.new(nil, 0)
      log "Initialized for '#{@hostname}'"
    end

    # Easy way to set a(n) SSH option(s).
    #
    # @param [Hash] options Net::SSH::Simple options.
    def set(**options)
      log "Adding options: #{options}"
      @options.merge! options
    end

    # Easy way to unset a(n) SSH option(s).
    #
    # @param [Array<Symbol>] option_keys One or many SSH options to unset.
    def unset(*option_keys)
      log "Unsetting options: #{option_keys}"

      option_keys.each do |key|
        @options.delete(key)
      end
    end

    # Runs +command+ on the host for which this SSH object is connected to.
    #
    # @param [String] command The command to run on the remote box.
    # @param [Hash] ssh_options Net::SSH::Simple options.  These will get merged
    #   with options set in #initialize and via #set.  Can be used to override
    #   those settings as well.
    # @return [Rosh::CommandResult]
    # @todo Attempt to coerce the output of the SSH command into a Ruby object.
    def run(command, **ssh_options)
      new_options = @options.merge(ssh_options)
      retried = false

      begin
        output = @ssh.ssh(@hostname, command, new_options, &ssh_block)
        Rosh::CommandResult.new(nil, output.exit_code, output)
      rescue Net::SSH::Simple::Error => ex
        log "Net::SSH::Simple::Error: #{ex}"

        if ex.wrapped.class == Net::SSH::AuthenticationFailed
          if retried
            puts 'Authentication failed.'.red
          else
            retried = true
            password = ask('Enter your password:  ') { |q| q.echo = false }
            new_options.merge! password: password
            retry
          end
        end

        if ex.wrapped.class == Net::SSH::Disconnect
          if retried
            $stdout.puts 'Tried to reconnect to the remote host, but failed.'.red
          else
            log 'Host disconnected us; retrying to connect...'
            retried = true
            @ssh = Net::SSH::Simple.new(@options)
            run(command, new_options)
            retry
          end
        end

        Rosh::CommandResult.new(nil, 1, ex)
      end
    end

    # Uploads +source+ file to the +destination+ path on the remote box.
    #
    # @param [String] source The source file to upload.
    # @param [String] destination The destination path to upload to.
    # @param [Hash] ssh_options Net::SSH::Simple options.  These will get merged
    #   with options set in #initialize and via #set.  Can be used to override
    #   those settings as well.
    # @return [Rosh::CommandResult]
    def upload(source, destination, **ssh_options)
      new_options = @options.merge(ssh_options)

      result = begin
        #output = @ssh.scp_ul(@hostname, source, destination, new_options, &ssh_block)
        output = @ssh.scp_ul(@hostname, source, destination, new_options)
        Rosh::CommandResult.new(nil, output.exit_code, output)
      rescue Net::SSH::Simple::Error => ex
        log "Net::SSH::Simple::Error: #{ex}"
        Rosh::CommandResult.new(nil, 1, ex)
      end

      log "SCP upload result: #{result.inspect}"

      result
    end

    # Closes the SSH connection and cleans up.
    def close
      @ssh.close
    end

    # @param [String] file The path of the file to cat.
    # @return [Rosh::CommandResult] On success, #exit_status is 0, #ruby_object
    #   is a String with the file contents.  On fail, #exit_status is 1,
    #   #ruby_object is a Rosh::ErrorNOENT error.
    def cat(file)
      process(file) do |full_file|
        result = run "cat #{full_file}"

        if result.ssh_result.stderr.match %r[No such file or directory]
          error = Rosh::ErrorENOENT.new(result.ssh_result.stderr)
          Rosh::CommandResult.new(error, result.exit_status, result.ssh_result)
        else
          result
        end
      end
    end

    # @param [String] path The path of the directory to change to.
    # @return [Rosh::CommandResult] On success, #exit_status is 0, #ruby_object
    #   is a Rosh::RemoteDir.  On fail, #exit_status is 1, #ruby_object is a
    #   Rosh::ErrorNOENT error.
    def cd(path)
      process(path) do |full_path|
        result = run "cd #{full_path} && pwd"

        if result.exit_status.zero?
          @internal_pwd = Rosh::RemoteDir.new(result.ruby_object, self)
          Rosh::CommandResult.new(@internal_pwd, 0, result.ssh_result)
        elsif result.ssh_result.stderr.match %r[No such file or directory]
          error = Rosh::ErrorENOENT.new(result.ssh_result.stderr)
          Rosh::CommandResult.new(error, result.exit_status, result.ssh_result)
        else
          result
        end
      end
    end

    # @param [String] source The path to the file to copy.
    # @param [String] destination The destination to copy the file to.
    # @return [Rosh::CommandResult] On success, #exit_status is 0, #ruby_object
    #   is +true+.  On fail, #exit_status is 1, #ruby_object is the Exception
    #   that was raised.
    def cp(source, destination)
      process(source, destination) do |full_source, full_destination|
        result = run "cp #{full_source} #{full_destination}"

        if result.ssh_result.stderr.match %r[No such file or directory]
          error = Rosh::ErrorENOENT.new(result.ssh_result.stderr)
          Rosh::CommandResult.new(error, result.exit_status, result.ssh_result)
        elsif result.ssh_result.stderr.match %r[omitting directory]
          error = Rosh::ErrorEISDIR.new(result.ssh_result.stderr)
          Rosh::CommandResult.new(error, result.exit_status, result.ssh_result)
        else
          Rosh::CommandResult.new(true, result.exit_status, result.ssh_result)
        end
      end
    end

    # @param [String] command The system command to execute.
    # @return [Rosh::CommandResult] On success, #exit_status is 0, #ruby_object
    #   is the output of the command as a String.  On fail, #exit_status is 1,
    #   #ruby_object is the output of the failed command as a String.
    def exec(command)
      process do
        command = "cd #{@internal_pwd.to_path} && #{command}"
        result = run(command)

        if result.exit_status.zero?
          result
        else
          Rosh::CommandResult.new(result.ssh_result.stderr, result.exit_status,
            result.ssh_result)
        end
      end
    end

    # @param [String] path Path to the directory to list its contents.
    # @return [Rosh::CommandResult] On success, #exit_status is 0, #ruby_object
    #   is an Array of Rosh::RemoteFileSystemObjects.  On fail, #exit_status is
    #   the status given by the remote host's failed 'ls' command, #ruby_object
    #   is a Rosh::ErrorENOENT.
    def ls(path=nil)
      process(path) do |full_path|
        result = run "ls #{full_path}"

        if result.ssh_result.stderr.match %r[No such file or directory]
          error = Rosh::ErrorENOENT.new(result.ssh_result.stderr)
          Rosh::CommandResult.new(error, result.exit_status, result.ssh_result)
        else
          listing = result.ruby_object.split.map do |entry|
            full_path = "#{full_path}/#{entry}"
            Rosh::RemoteFileSystemObject.create(full_path, self)
          end

          Rosh::CommandResult.new(listing, 0, result.ssh_result)
        end
      end
    end

    # Runs `ps auxe` on the remote host and converts each line of process info
    # to a Rosh::RemoteProcTable.
    #
    # @return [Rosh::CommandResult] #exit_status is 0, #ruby_object is an Array
    #   of Rosh::RemoteProcTable objects.
    def ps
      process do
        result = run('ps auxe')
        list = []

        result.ssh_result.stdout.each_line do |line|
          match_data = %r[(?<user>\S+)\s+(?<pid>\S+)\s+(?<cpu>\S+)\s+(?<mem>\S+)\s+(?<vsz>\S+)\s+(?<rss>\S+)\s+(?<tty>\S+)\s+(?<stat>\S+)\s+(?<start>\S+)\s+(?<time>\S+)\s+(?<cmd>[^\n]+)].match(line)

          next if match_data[:user] == 'USER'
          list << Rosh::RemoteProcTable.new(
            match_data[:user],
            match_data[:pid].to_i,
            match_data[:cpu].to_f,
            match_data[:mem].to_f,
            match_data[:vsz].to_i,
            match_data[:rss].to_i,
            match_data[:tty],
            match_data[:stat],
            Time.parse(match_data[:start]),
            match_data[:time],
            match_data[:cmd].strip
          )
        end

        Rosh::CommandResult.new(list, 0)
      end
    end

    # @return [Rosh::CommandResult] On success, #exit_status is 0, #ruby_object
    #   is a Rosh::RemoteDir.
    def pwd
      unless @internal_pwd
        result = run('pwd')
        @internal_pwd = Rosh::RemoteDir.new(result.ruby_object, self)
      end

      @last_result = Rosh::CommandResult.new(@internal_pwd, 0)
    end

    def ruby(code)
      Rosh::CommandResult.new('Not implemented', 1)
    end

    # @return [Rosh::CommandResult] The result of the last command executed.  If
    #   no command has been executed, #ruby_object is nil; #exit_status is 0.
    def _?
      return @last_result if @last_result

      Rosh::CommandResult(nil, 0)
    end

    private

    # DRYed up block to hand over to SSH commands for keeping handling of stdout
    # and stderr output.
    #
    # @return [Lambda]
    def ssh_block
      @ssh_block ||= lambda do |event, _, data|
        case event
        when :start
          $stdout.puts 'Starting SSH command...'
        when :stdout
          (@buffer ||= '') << data

          while line = @buffer.slice!(/(.*)\r?\n/)
            $stdout.print line.light_blue
          end
        when :stderr
          (@buffer ||= '') << data

          while line = @buffer.slice!(/(.*)\r?\n/)
            $stderr.print line.light_red
          end
        when :finish
          $stdout.puts 'Finished executing command.'.light_blue
        end
      end
    end

    def process(*paths, &block)
      @last_result = if paths.empty?
        pwd unless @internal_pwd
        block.call
      else
        full_paths = paths.map { |path| preprocess_path(path) }
        block.call(*full_paths)
      end
    end

    def preprocess_path(path)
      path = '' unless path
      path.strip!

      pwd unless @internal_pwd

      unless path.start_with?('/') || path.start_with?('$')
        path = "#{@internal_pwd.to_path}/#{path}"
      end

      path
    end
  end
end

Rosh::RemoteShell.log_class_name = true
