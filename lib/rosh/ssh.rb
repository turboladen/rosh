require 'etc'
require 'net/ssh/simple'
require 'highline/import'
require 'log_switch'
require_relative 'command_result'


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
  class SSH
    #include LogSwitch::Mixin

    DEFAULT_USER = Etc.getlogin
    DEFAULT_TIMEOUT = 1800

    # @return [Hash] The Net::SSH::Simple options that were during initialization
    #   and via #set.
    attr_reader :options

    attr_reader :hostname

    # @param [String] hostname Name or IP of the host to SSH in to.
    # @param [Hash] options Net::SSH::Simple options.
    def initialize(hostname, **options)
      @hostname = hostname
      @options = options

      @options[:user] = DEFAULT_USER unless @options.has_key? :user
      @options[:timeout] = DEFAULT_TIMEOUT unless @options.has_key? :timeout
      @ssh = Net::SSH::Simple.new(@options)
    end

    # Easy way to set a(n) SSH option(s).
    #
    # @param [Hash] options Net::SSH::Simple options.
    def set(**options)
      #log "Adding options: #{options}"
      puts "Adding options: #{options}"
      @options.merge! options
    end

    # Easy way to unset a(n) SSH option(s).
    #
    # @param [Array<Symbol>] option_keys One or many SSH options to unset.
    def unset(*option_keys)
      #log "Unsetting options: #{option_keys}"
      puts "Unsetting options: #{option_keys}"

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
      @retried = false

      begin
        output = @ssh.ssh(@hostname, command, new_options, &ssh_block)
        Rosh::CommandResult.new(nil, output.exit_code, output)
      rescue Net::SSH::Simple::Error => ex
        #log "Net::SSH::Simple::Error: #{ex}"
        puts "Net::SSH::Simple::Error: #{ex}"

        if ex.wrapped.class == Net::SSH::AuthenticationFailed
          if @retried
            puts 'Authentication failed.'.red
          else
            @retried = true
            password = ask('Enter your password:  ') { |q| q.echo = false }
            new_options.merge! password: password
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
        #log "Net::SSH::Simple::Error: #{ex}"
        puts "Net::SSH::Simple::Error: #{ex}"
        Rosh::CommandResult.new(nil, 1, ex)
      end

      #log "SCP upload result: #{result.inspect}"
      puts "SCP upload result: #{result.inspect}"
      result
    end

    # Closes the SSH connection and cleans up.
    def close
      @ssh.close
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
          #log 'Starting SSH command...'
          puts 'Starting SSH command...'
        when :stdout
          (@buffer ||= '') << data

          while line = @buffer.slice!(/(.*)\r?\n/)
            print line.light_blue
          end
        when :stderr
          (@buffer ||= '') << data

          while line = @buffer.slice!(/(.*)\r?\n/)
            print line.light_red
          end
        when :finish
          puts 'Finished executing command.'.light_blue
        end
      end
    end
  end
end
