require 'etc'
require 'colorize'
require 'net/ssh/simple'
require 'highline/import'
require 'log_switch'

require_relative '../command_result'
require_relative 'remote_file_system_object'
require_relative 'remote_dir'
require_relative 'remote_proc_table'
require_relative '../errors'


class Rosh
  class Host

    # Wrapper for Net::SSH::Simple to allow for a) not having to pass in the
    # hostname with every SSH call, and b) handle STDOUT and STDERR the same way
    # across SSH builtin_commands.
    #
    # Any options passed in to #initialize or set using #set will be used with
    # subsequent #run or #upload commands.
    #
    # Example use:
    #   ssh = Rosh::Host::RemoteShell.new '10.0.0.1', keys: [Dir.home + '/.ssh/keyfile'], port: 2222
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
      attr_reader :last_exit_status
      attr_reader :last_exception

      # @param [String] hostname Name or IP of the host to SSH in to.
      # @param [Hash] options Net::SSH::Simple options.
      def initialize(hostname, **options)
        @hostname = hostname
        @options = options

        @options[:user] = DEFAULT_USER unless @options.has_key? :user
        @options[:timeout] = DEFAULT_TIMEOUT unless @options.has_key? :timeout
        @ssh = Net::SSH::Simple.new(@options)

        @internal_pwd = nil
        @history = []

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
      #
      # @return [Rosh::CommandResult]
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
      #
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
      #
      # @return [String, ROSH::ErrorNOENT] On success, returns the contents of
      #   the file as a String.  On fail, #last_exit_status is set to the exit
      #   status from the remote command, and a Rosh::ErrorNOENT error is
      #   returned.
      def cat(file)
        log "cat was called with arg '#{file}'"
        full_file = preprocess_path(file)

        process(:cat, file: file) do
          result = run "cat #{full_file}"

          if result.ssh_result.stderr.match %r[No such file or directory]
            error = Rosh::ErrorENOENT.new(result.ssh_result.stderr)
            [error, result.exit_status, result.ssh_result]
          else
            [result.ruby_object, 0, result.ssh_result]
          end
        end
      end

      # @param [String] path The absolute or relative path to make the new
      #   working directory.
      #
      # @return [Boolean] On success, returns a Rosh::RemoteDir.  On
      #   fail, #last_exit_status is set to the exit status from the remote
      #   command, Rosh::ErrorNOENT error.
      def cd(path)
        log "cat called with arg '#{path}'"
        full_path = preprocess_path(path)

        process(:cat, path: path) do
          result = run "cd #{full_path} && pwd"

          if result.exit_status.zero?
            @internal_pwd = Rosh::Host::RemoteDir.new(result.ruby_object, self)

            [true, 0, result.ssh_result]
          elsif result.ssh_result.stderr.match %r[No such file or directory]
            error = Rosh::ErrorENOENT.new(result.ssh_result.stderr)

            [error, result.exit_status, result.ssh_result]
          else
            [result.ruby_object, result.exit_status, result.ssh_result]
          end
        end
      end

      # @param [String] source The path to the file to copy.
      # @param [String] destination The destination to copy the file to.
      #
      # @return [TrueClass,Rosh::ErrorENOENT,Rosh::ErrorEISDIR] On success,
      #   returns +true+.  On fail, #last_exit_status is set to the exit status
      #   from the remote command, returns the exception that was raised.
      def cp(source, destination)
        log "cp called with args '#{source}', '#{destination}'"
        full_source = preprocess_path(source)
        full_destination = preprocess_path(destination)

        process(:cp, source: source, destination: destination) do
          result = run "cp #{full_source} #{full_destination}"

          if result.ssh_result.stderr.match %r[No such file or directory]
            error = Rosh::ErrorENOENT.new(result.ssh_result.stderr)

            [error, result.exit_status, result.ssh_result]
          elsif result.ssh_result.stderr.match %r[omitting directory]
            error = Rosh::ErrorEISDIR.new(result.ssh_result.stderr)

            [error, result.exit_status, result.ssh_result]
          else
            [true, result.exit_status, result.ssh_result]
          end
        end
      end

      # @param [String] command The system command to execute.
      #
      # @return [String] On success, returns the output of the command.  On
      #   fail, #last_exit_status is set to the exit status of the remote command,
      #   returns the output of the failed command as a String.  If STDOUT and
      #   STDERR were both written to during a non-0 resulting command, those
      #   strings will be concatenated and separated by 2 \n's.
      def exec(command)
        log "exec called with command '#{command}'"

        process(:exec, command: command) do
          command = "cd #{@internal_pwd.to_path} && #{command}"
          result = run(command)

          if result.exit_status.zero?
            [result.ruby_object, 0, result.ssh_result]
          else
            ssh = result.ssh_result
            output = if ssh.stdout.empty? && ssh.stderr.empty?
              ''
            elsif ssh.stderr.empty?
              ssh.stdout.strip
            elsif ssh.stdout.empty?
              ssh.stderr.strip
            else
              ssh.stdout.strip + "\n\n" + ssh.stderr.strip
            end

            [output, result.exit_status, result.ssh_result]
          end
        end
      end

      # @param [Integer] status Exit status code.
      def exit(status=0)
        Kernel.exit(status)
      end

      # @param [String] path Path to the directory to list its contents.  If no
      #   path given, lists the current working directory.
      #
      # @return [Array<Rosh::RemoteFileSystemObject>, Rosh::ErrorENOENT] On
      #   success, returns an Array of Rosh::RemoteFileSystemObjects.  On fail,
      #   #last_exit_status is set to the status given by the remote host's
      #   failed 'ls' command, returns a Rosh::ErrorENOENT.
      def ls(path=nil)
        log "ls called with arg '#{path}'"
        base = preprocess_path(path)

        process(:ls, path: path) do
          result = run "ls #{base}"

          if result.ssh_result.stderr.match %r[No such file or directory]
            error = Rosh::ErrorENOENT.new(result.ssh_result.stderr)

            [error, result.exit_status, result.ssh_result]
          else
            listing = result.ruby_object.split.map do |entry|
              full_path = "#{base}/#{entry}"
              Rosh::Host::RemoteFileSystemObject.create(full_path, self)
            end

            [listing, 0, result.ssh_result]
          end
        end
      end

      # Runs `ps auxe` on the remote host and converts each line of process info
      # to a Rosh::RemoteProcTable.
      #
      # @param [String] name The name of a command to filter on.
      # @param [Integer] pid The pid of a command to find.
      #
      # @return [Array<Rosh::Host::RemoteProcTable>, Rosh::Host::RemoteProcTable] When :name
      #   or no options are given, returns an Array of Rosh::RemoteProcTable
      #   objects; when :pid is given, a single Rosh::RemoteProcTable is returned.
      def ps(name: nil, pid: nil)
        log "ps called with args 'name: #{name}', 'pid: #{pid}'"

        process(:ps, name: name, pid: pid) do
          result = run('ps auxe')
          list = []

          result.ssh_result.stdout.each_line do |line|
            match_data = %r[(?<user>\S+)\s+(?<pid>\S+)\s+(?<cpu>\S+)\s+(?<mem>\S+)\s+(?<vsz>\S+)\s+(?<rss>\S+)\s+(?<tty>\S+)\s+(?<stat>\S+)\s+(?<start>\S+)\s+(?<time>\S+)\s+(?<cmd>[^\n]+)].match(line)

            next if match_data[:user] == 'USER'
            list << Rosh::Host::RemoteProcTable.new(
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

          if name
            p = list.find_all { |i| i.command =~ /\b#{name}\b/ }
            [p, 0, result.ssh_result]
          elsif pid
            p = list.find_all { |i| i.pid == pid }
            [p, 0, result.ssh_result]
          else
            [list, 0, result.ssh_result]
          end
        end
      end

      # @return [Rosh::RemoteDir] The current working directory.
      log 'pwd called'

      def pwd
        if @internal_pwd
          process(:pwd) { [@internal_pwd, 0, nil] }
        else
          result = run('pwd')
          @internal_pwd = Rosh::Host::RemoteDir.new(result.ruby_object, self)

          process(:pwd) { [@internal_pwd, 0, result.ssh_result] }
        end
      end

      def ruby(code)
        process { ['Not implemented!', 1, nil] }
      end

      # @return [Rosh::CommandResult] The result of the last command executed.  If
      #   no command has been executed, #ruby_object is nil; #exit_status is 0.
      def last_result
        @history.last[:output]
      end
      alias :__ :last_result

      def last_exit_status
        @history.last[:exit_status]
      end
      alias :_? :last_exit_status

      # @return The last exception that was raised.
      def last_exception
        @history.reverse.find { |result| result[:output].kind_of? Exception }
      end
      alias :_! :last_exception

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

      def process(cmd, **args, &block)
        pwd unless @internal_pwd

        output, exit_status, ssh_output = block.call

        @history << {
          command: cmd,
          arguments: args,
          output: output,
          exit_status: exit_status,
          ssh_output: ssh_output
        }

        output
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
end

Rosh::Host::RemoteShell.log_class_name = true
