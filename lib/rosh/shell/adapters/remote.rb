require 'etc'
require 'log_switch'
require 'net/ssh'
require 'net/scp'
require 'yaml'
require 'time'
require 'awesome_print'

require_relative '../command_result'


class Rosh
  class Shell
    module Adapters
      SSHResult = Struct.new(:stdout, :stderr, :exit_status, :exit_signal)

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
      module Remote
        include Net::SSH::PromptMethods::Highline

        DEFAULT_USER = Etc.getlogin

        extend LogSwitch
        include LogSwitch::Mixin

        def user=(new_user)
          @user = new_user
        end

        def ssh_options
          @ssh_options ||= {}
        end

        def ssh_options=(new_options)
          @ssh_options = new_options
        end

        # Uploads +source+ file to the +destination+ path on the remote box.
        #
        # @param [String] source The source file to upload.
        # @param [String] destination The destination path to upload to.
        #
        # @return [Rosh::Shell::CommandResult]
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

            log "doing upload with options #{ssh_options}"
            log "sudo is #{@sudo}"
            scp(source, destination)

            Rosh::Shell::CommandResult.new(nil, 0)
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
                ssh_options.merge! password: password
                log "Password added.  options: #{ssh_options}"
                retry
              end
            end

            Rosh::Shell::CommandResult.new(ex, 1)
          end

          if @sudo && doing_sudo_upload
            log 'sudo is set during SCP and doing upload'
            unless su_user_name == 'root'
              @sudo = false
              exec("chown #{su_user_name} #{destination}")
              @sudo = true
            end

            exec("cat #{destination} > #{original_dest} && rm #{destination}")
            return current_shell.last_exit_status.zero?
          end

          log "SCP upload result: #{result.inspect}"

          result
        end

        # @param [String] file The path of the file to cat.
        #
        # @return [String, ROSH::ErrorNOENT] On success, returns the contents of
        #   the file as a String.  On fail, #last_exit_status is set to the exit
        #   status from the remote command, and a Rosh::ErrorNOENT error is
        #   returned.
        def cat(file)
          cmd = sudoize("cat #{file}")
          result = run(cmd)

          if result.stderr.match %r[No such file or directory]
            error = Rosh::ErrorENOENT.new(result.stderr)

            [error, result.exit_status, result.stdout, result.stderr]
          else
            good_info result.stdout

            [result.ruby_object, 0, result.stdout, result.stderr]
          end
        end

        # @param [String] path The absolute or relative path to make the new
        #   working directory.
        #
        # @return [Boolean] On success, returns a Rosh::Host::FileSystemObjects::RemoteDir.  On
        #   fail, #last_exit_status is set to the exit status from the remote
        #   command, Rosh::ErrorNOENT error.
        def cd(path)
          cmd = sudoize("cd #{path} && pwd")
          log %[CD: #{cmd}]
          result = run(cmd)

          if result.exit_status.zero?
            [true, 0, result.stdout, result.stderr]
          elsif result.stderr.match %r[No such file or directory]
            error = Rosh::ErrorENOENT.new(result.stderr)

            [error, result.exit_status, result.stdout, result.stderr]
          else
            result
          end
        end

        # @param [String] source The path to the file to copy.
        # @param [String] destination The destination to copy the file to.
        #
        # @return [TrueClass,Rosh::ErrorENOENT,Rosh::ErrorEISDIR] On success,
        #   returns +true+.  On fail, #last_exit_status is set to the exit status
        #   from the remote command, returns the exception that was raised.
        def cp(source, destination)
          cmd = sudoize("cp #{source} #{destination}")
          log %[CP: #{cmd}]
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

        # @param [String] command The system command to execute.
        #
        # @return [String] On success, returns the output of the command.  On
        #   fail, #last_exit_status is set to the exit status of the remote command,
        #   returns the output of the failed command as a String.  If STDOUT and
        #   STDERR were both written to during a non-0 resulting command, those
        #   strings will be concatenated and separated by 2 \n's.
        def exec(command, internal_pwd='')
          command = sudoize("cd #{internal_pwd} && #{command}")

          log %[EXEC: #{command}]
          run_info(command)
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

        # @param [String] path Path to the directory to list its contents.  If no
        #   path given, lists the current working directory.
        #
        # @return [Array<Rosh::RemoteBase>, Rosh::ErrorENOENT] On
        #   success, returns an Array of Rosh::RemoteFileSystemObjects.  On fail,
        #   #last_exit_status is set to the status given by the remote host's
        #   failed 'ls' command, returns a Rosh::ErrorENOENT.
        def ls(path)
          cmd = sudoize("ls #{path}")
          log %[LS: #{cmd}]
          result = run(cmd)

          if result.stderr.match %r[No such file or directory]
            error = Rosh::ErrorENOENT.new(result.stderr)

            return [error, result.exit_status, result.stdout, result.stderr]
          end

          return([]) if result.ruby_object.nil?

          listing = result.ruby_object.split.map do |entry|
            full_path = path == '/' ? "/#{entry}" : "#{path}/#{entry}"
            good_info full_path

            Rosh::FileSystem.create(full_path, @host_name)
          end.compact

          [listing, 0, result.stdout, result.stderr]
        end

        def ruby(code)
          ['Not implemented!', 1, nil]
        end

        def preprocess_path(path, internal_pwd)
          unless path.start_with?('/') || path.start_with?('$')
            path = "#{internal_pwd}/#{path}"
          end

          path
        end

        #-----------------------------------------------------------------------
        # Privates
        #-----------------------------------------------------------------------
        private

        def ssh
          @ssh ||= new_ssh
        end

        def new_ssh
          Net::SSH.start(@host_name, @user, ssh_options)
        end

        # Runs +command+ on the host for which this SSH object is connected to.
        #
        # @param [String] command The command to run on the remote box.
        #
        # @return [Rosh::Shell::CommandResult]
        def run(command)
          retried = false

          begin
            result = ssh_exec(command)
            Rosh::Shell::CommandResult.new(nil, result.exit_status, result.stdout, result.stderr)
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
                ssh_options.merge! password: password
                log "Password added.  options: #{ssh_options}"
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

            Rosh::Shell::CommandResult.new(ex, 1)
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
                  unless ssh_options[:password]
                    ssh_options[:password] = prompt("\n<ROSH> Enter your password:  ", false)
                  end

                  ch.send_data "#{ssh_options[:password]}\n"
                  ch.eof!
                end

                stdout_data << data
              end

              run_info(command)
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

        def sudoize(cmd)
          #if sudo && su_user_name && su_user_name != 'root'
          if sudo
            name = su_user_name || 'root'
            %[sudo su #{name} -c "#{cmd}"]
            #elsif sudo
            #  %[sudo -s -- "#{cmd}"]
          else
            cmd
          end
        end

        self.log_class_name = true
      end
    end
  end
end

