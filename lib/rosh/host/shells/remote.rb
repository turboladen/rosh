require 'etc'
require 'net/ssh'
require 'net/scp'

require_relative 'base'
require_relative '../remote_file_system_object'
require_relative '../remote_dir'
require_relative '../remote_proc_table'


class Rosh
  class Host
    SSHResult = Struct.new(:stdout, :stderr, :exit_status, :exit_signal)

    module Shells

      # Wrapper for Net::SSH to allow for a) not having to pass in the
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
      class Remote < Base
        extend LogSwitch
        include LogSwitch::Mixin
        include Net::SSH::PromptMethods::Highline

        DEFAULT_USER = Etc.getlogin
        DEFAULT_TIMEOUT = 1800

        # @return [Hash] The Net::SSH options that were during initialization
        #   and via #set.
        attr_reader :options

        attr_reader :hostname
        attr_reader :user

        # @param [String] hostname Name or IP of the host to SSH in to.
        # @param [Hash] options Net::SSH options.
        def initialize(hostname, **options)
          super()
          @hostname = hostname
          @options = options
          @user = @options.delete(:user) || DEFAULT_USER

          @options[:timeout] = DEFAULT_TIMEOUT unless @options.has_key? :timeout
          log "Net::SSH.configuration: #{Net::SSH.configuration_for(@hostname)}"
          @ssh = new_ssh

          @internal_pwd = nil
          @history = []

          at_exit do
            @ssh.close unless @ssh.closed?
          end

          log "Initialized for '#{@hostname}'"
        end

        # Easy way to set a(n) SSH option(s).
        #
        # @param [Hash] options Net::SSH options.
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
        # @param [Hash] ssh_options Net::SSH options.  These will get merged
        #   with options set in #initialize and via #set.  Can be used to override
        #   those settings as well.
        #
        # @return [Rosh::CommandResult]
        def run(command)
          retried = false

          begin
            result = ssh_exec(command)
            log "Result: #{result}"
            Rosh::CommandResult.new(nil, result.exit_status, result.stdout, result.stderr)
          rescue => ex
            log "Error: #{ex.class}"
            log "Error: #{ex.message}"
            log "Error: #{ex.backtrace.join("\n")}"

            if ex.class == Net::SSH::AuthenticationFailed
              if retried
                bad_info 'Authentication failed.'
              else
                retried = true
                password = prompt("\n<ROSH> Enter your password:  ", false)
                @options.merge! password: password
                @ssh = new_ssh
                retry
              end
            end

=begin
            if ex.class == Net::SSH::Disconnect
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
=end

            Rosh::CommandResult.new(ex, 1)
          end
        end

        # Uploads +source+ file to the +destination+ path on the remote box.
        #
        # @param [String] source The source file to upload.
        # @param [String] destination The destination path to upload to.
        # @param [Hash] ssh_options Net::SSH options.  These will get merged
        #   with options set in #initialize and via #set.  Can be used to override
        #   those settings as well.
        #
        # @return [Rosh::CommandResult]
        def upload(source, destination, **ssh_options)
          new_options = @options.merge(ssh_options)

          result = begin
            stdout_data = ''

            Net::SCP.upload!(@hostname, @user, source, destination, new_options) do |ch, name, sent, total|
              ch.on_data do |ch, data|
                good_info data

                if data.match /sudo\] password/
                  unless @options[:password]
                    @options[:password] = prompt("\n<ROSH> Enter your password:  ", false)
                  end

                  ch.send_data "#{@options[:password]}\n"
                  ch.eof!
                end

                stdout_data << data
              end

              puts "#{name}: #{sent}/#{total}"
            end

            Rosh::CommandResult.new(nil, 0, stdout_data)
          rescue => ex
            log "Exception: #{ex.class}"
            log "Exception: #{ex.message}"
            log "Exception: #{ex.backtrace.join("\n")}"
            Rosh::CommandResult.new(ex, 1, stdout_data)
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
            cmd = "cat #{full_file}"
            cmd.insert(0, 'sudo ') if @sudo
            result = run(cmd)

            if result.stderr.match %r[No such file or directory]
              error = Rosh::ErrorENOENT.new(result.stderr)
              [error, result.exit_status, result.stdout, result.stderr]
            else
              [result.ruby_object, 0, result.stdout, result.stderr]
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
            cmd = "cd #{full_path} && pwd"
            cmd.insert(0, 'sudo ') if @sudo
            result = run(cmd)

            if result.exit_status.zero?
              @internal_pwd = Rosh::Host::RemoteDir.new(result.ruby_object, self)

              [true, 0, result.stdout, result.stderr]
            elsif result.stderr.match %r[No such file or directory]
              error = Rosh::ErrorENOENT.new(result.stderr)

              [error, result.exit_status, result.stdout, result.stderr]
            else
              result
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
            cmd = "cp #{full_source} #{full_destination}"
            cmd.insert(0, 'sudo ') if @sudo
            result = run(cmd)

            if result.stderr.match %r[No such file or directory]
              error = Rosh::ErrorENOENT.new(result.stderr)

              [error, result.exit_status, result.stdout, result.stderr]
            elsif result.stderr.match %r[omitting directory]
              error = Rosh::ErrorEISDIR.new(result.stderr)

              [error, result.exit_status, result.stdout, result.stderr]
            else
              [true, result.exit_status, result.stdout, result.stderr]
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
          command = %[sudo -s -- #{command}] if @sudo
          log "exec called with command '#{command}'"

          process(:exec, command: command) do
            command = "cd #{@internal_pwd.to_path} && #{command}"
            result = run(command)

            if result.exit_status.zero?
              [result.ruby_object, 0, result.stdout]
            else
              output = if result.stdout.empty? && result.stderr.empty?
                ''
              elsif result.stderr.empty?
                result.stdout.strip
              elsif result.stdout.empty?
                result.stderr.strip
              else
                result.stdout.strip + "\n\n" + result.stderr.strip
              end

              [output, result.exit_status, result.stdout, result.stderr]
            end
          end
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
            cmd = "ls #{base}"
            cmd.insert(0, 'sudo ') if @sudo
            result = run(cmd)

            if result.stderr.match %r[No such file or directory]
              error = Rosh::ErrorENOENT.new(result.stderr)

              [error, result.exit_status, result.stdout, result.stderr]
            else
              listing = result.ruby_object.split.map do |entry|
                full_path = "#{base}/#{entry}"
                Rosh::Host::RemoteFileSystemObject.create(full_path, self)
              end

              [listing, 0, result.stdout, result.stderr]
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
            cmd = 'ps auxe'
            cmd.insert(0, 'sudo ') if @sudo
            result = run(cmd)
            list = []

            result.stdout.each_line do |line|
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
              [p, 0, result.stdout, result.stderr]
            elsif pid
              p = list.find_all { |i| i.pid == pid }
              [p, 0, result.stdout, result.stderr]
            else
              [list, 0, result.stdout, result.stderr]
            end
          end
        end

        # @return [Rosh::RemoteDir] The current working directory.
        def pwd
          log 'pwd called'

          if @internal_pwd
            process(:pwd) { [@internal_pwd, 0, nil] }
          else
            result = run('pwd')
            @internal_pwd = Rosh::Host::RemoteDir.new(result.ruby_object, self)

            process(:pwd) { [@internal_pwd, 0, result.stdout, result.stderr] }
          end
        end

        def ruby(code)
          process { ['Not implemented!', 1, nil] }
        end

        private

        def new_ssh
          Net::SSH.start(@hostname, @user, @options)
        end

        # DRYed up block to hand over to SSH commands for keeping handling of stdout
        # and stderr output.
        #
        # @return [Lambda]
        def ssh_exec(command)
          stdout_data = ''
          stderr_data = ''
          exit_status = nil
          exit_signal = nil

          @ssh.open_channel do |channel|
            channel.request_pty do |ch, success|
              raise 'Could not obtain pty' unless success

              ch.on_data do |ch, data|
                good_info data

                if data.match /sudo\] password/
                  unless @options[:password]
                    @options[:password] = prompt("\n<ROSH> Enter your password:  ", false)
                  end

                  ch.send_data "#{@options[:password]}\n"
                  ch.eof!
                end

                stdout_data << data
              end

              ch.exec(command)
            end

            channel.on_extended_data do |_, data|
              bad_info data.to_s
              stderr_data << data
            end

            channel.on_request('exit-status') do |_, data|
              exit_status = data.read_long
            end

            channel.on_request('exit-signal') do |_, data|
              exit_signal = data.read_long
            end
          end

          @ssh.loop

          SSHResult.new(stdout_data, stderr_data, exit_status, exit_signal)
        end

        def process(cmd, **args, &block)
          pwd unless @internal_pwd

          super(cmd, **args, &block)
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
end

Rosh::Host::Shells::Remote.log_class_name = true
