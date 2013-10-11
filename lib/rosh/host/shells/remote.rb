require 'etc'
require 'net/ssh'
require 'net/scp'
require 'yaml'

require_relative 'base'
require_relative '../../file_system/directory'
require_relative '../wrapper_methods/remote'


class Rosh
  class Host
    SSHResult = Struct.new(:stdout, :stderr, :exit_status, :exit_signal)

    module Shells

      # Wrapper for Net::SSH to allow for a) not having to pass in the
      # host_name with every SSH call, and b) handle STDOUT and STDERR the same way
      # across SSH builtin_commands.
      #
      # Any options passed in to #initialize or set using #set will be used with
      # subsequent #run or #upload commands.
      #
      # Example use:
      #   ssh = Rosh::Host::Shells::Remote.new '10.0.0.1', keys: [Dir.home + '/.ssh/keyfile'], port: 2222
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
        include WrapperMethods::Remote

        DEFAULT_USER = Etc.getlogin

        # @return [Hash] The Net::SSH options that were during initialization
        #   and via #set.
        attr_reader :options

        attr_reader :host_name
        attr_reader :user

        # @param [String] host_name Name or IP of the host to SSH in to.
        # @param [String] output_commands Toggle for outputting all commands
        #   that were executed.  Note that some operations comprise of multiple
        #   commands.
        # @param [Hash] options Net::SSH options.
        def initialize(host_name, output_commands=true, **options)
          super(output_commands)
          @host_name = host_name
          @options = options
          @user = @options.delete(:user) || DEFAULT_USER
          log "New Remote shell.  options: #{@options}"

          log "Net::SSH.configuration: #{Net::SSH.configuration_for(@host_name)}"
          @ssh = nil

          @internal_pwd = nil
          @history = []

          at_exit do
            if @ssh
              @ssh.close unless @ssh.closed?
            end
          end

          log "Initialized for '#{@host_name}'"
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

        # Uploads +source+ file to the +destination+ path on the remote box.
        #
        # @param [String] source The source file to upload.
        # @param [String] destination The destination path to upload to.
        #
        # @return [Rosh::CommandResult]
        def upload(source, destination, doing_sudo_upload=false, original_dest=nil)
          retried = false

          result = begin
            if @sudo && !doing_sudo_upload
              log 'sudo is set during #upload'
              original_dest = destination
              destination = '/tmp/rosh_upload'

              upload(source, destination, true, original_dest)
              return
            end

            log "doing upload with options #{@options}"
            log "sudo is #{@sudo}"
            scp(source, destination)

            Rosh::CommandResult.new(nil, 0)
          rescue StandardError => ex
            log "Exception: #{ex.class}".red
            log "Exception: #{ex.message}".red
            log "Exception: #{ex.backtrace.join("\n")}".red

            if ex.class == Net::SSH::AuthenticationFailed
              if retried
                bad_info 'Authentication failed.'
              else
                retried = true
                password = prompt("\n<ROSH> Enter your password:  ", false)
                @options.merge! password: password
                log "Password added.  options: #{@options}"
                retry
              end
            end

            Rosh::CommandResult.new(ex, 1)
          end

          if @sudo && doing_sudo_upload
            log 'sudo is set during SCP and doing upload'
            exec("cp #{destination} #{original_dest} && rm #{destination}")
            return last_exit_status.zero?
          end

          log "SCP upload result: #{result.inspect}"

          result
        end

        # @param [String] path The absolute or relative path to make the new
        #   working directory.
        #
        # @return [Boolean] On success, returns a Rosh::Host::FileSystemObjects::RemoteDir.  On
        #   fail, #last_exit_status is set to the exit status from the remote
        #   command, Rosh::ErrorNOENT error.
        def cd(path)
          log "cd called with arg '#{path}'"
          full_path = preprocess_path(path)

          process(:cd, path: path) do
            cmd = "cd #{full_path} && pwd"
            cmd.insert(0, 'sudo ') if @sudo
            result = run(cmd)

            if result.exit_status.zero?
              @internal_pwd = result.ruby_object.strip

              [true, 0, result.stdout, result.stderr]
            elsif result.stderr.match %r[No such file or directory]
              error = Rosh::ErrorENOENT.new(result.stderr)

              [error, result.exit_status, result.stdout, result.stderr]
            else
              result
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
            command = "cd #{@internal_pwd} && #{command}"
            result = run(command)

            if result.exit_status.zero?
              good_info result.stdout unless result.stdout.empty?

              [result.ruby_object, 0, result.stdout]
            else
              good_info result.stdout unless result.stdout.empty?
              output = if result.stdout.empty? && result.stderr.empty?
                ''
              elsif result.stderr.empty?
                good_info result.stdout

                result.stdout
              elsif result.stdout.empty?
                bad_info result.stderr

                result.stderr
              else
                good_info result.stdout
                puts "\n\n"
                bad_info result.stderr

                result.stdout + "\n\n" + result.stderr
              end

              [output, result.exit_status, result.stdout, result.stderr]
            end
          end
        end

        # @return [Rosh::Host::FileSystemObjects::RemoteDir] The current working directory.
        def pwd
          log 'pwd called'

          output = process(:pwd) { [_pwd, 0, nil] }
          puts output.to_path

          output
        end

        def _pwd
          Rosh::Host::FileSystem::Directory.new(@internal_pwd, @host_name)
        end

        def ruby(code)
          process { ['Not implemented!', 1, nil] }
        end

        # Called by serializer when dumping.
        def encode_with(coder)
          coder['host_name'] = @host_name
          coder['user'] = @user
          o = @options.dup
          o.delete(:password) if o[:password]
          o.delete(:user) if o[:user]

          coder['options'] = o
        end

        # Called by serializer when loading.
        def init_with(coder)
          @user = coder['user']
          @options = coder['options']
          @host_name = coder['host_name']
          @sudo = false
          @history = []
        end

        #-----------------------------------------------------------------------
        # Privates
        #-----------------------------------------------------------------------
        private

        def ssh
          @ssh ||= new_ssh
        end

        def new_ssh
          Net::SSH.start(@host_name, @user, @options)
        end

        # Runs +command+ on the host for which this SSH object is connected to.
        #
        # @param [String] command The command to run on the remote box.
        #
        # @return [Rosh::CommandResult]
        def run(command)
          retried = false

          begin
            result = ssh_exec(command)
            Rosh::CommandResult.new(nil, result.exit_status, result.stdout, result.stderr)
          rescue StandardError => ex
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
                log "Password added.  options: #{@options}"
                @ssh = new_ssh
                retry
              end
            end

            if ex.class == Net::SSH::Disconnect
              if retried
                bad_info 'Tried to reconnect to the remote host, but failed.'
              else
                log 'Host disconnected us; retrying to connect...'
                retried = true
                @ssh = new_ssh
                run(command)
                retry
              end
            end

            Rosh::CommandResult.new(ex, 1)
          end
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

          ssh.open_channel do |channel|
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

              run_info(command) if @output_commands
              r = ch.exec(command)
              channel.close if r
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

          ssh.loop

          SSHResult.new(stdout_data, stderr_data, exit_status, exit_signal)
        end

        # DRYed up block to hand over to SSH commands for keeping handling of stdout
        # and stderr output.
        #
        # @return [Lambda]
        def scp(source, destination)
          ssh.scp.upload!(source, destination) do |ch, name, rec, total|
            percentage = format('%.2f', rec.to_f / total.to_f * 100) + '%'
            print "Saving to #{name}: Received #{rec} of #{total} bytes" + " (#{percentage})               \r"
            $stdout.flush
          end
        end

        def process(cmd, **args, &block)
          unless @internal_pwd
            @internal_pwd = run('pwd').ruby_object.strip
          end

          super(cmd, **args, &block)
        end

        def preprocess_path(path)
          #path ||= ''
          path = path.to_s.strip
          @internal_pwd = run('pwd').ruby_object.strip

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
