require 'time'
require_relative '../remote_proc_table'


class Rosh
  class Host
    module WrapperMethods
      module Remote

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
              good_info result.stdout

              [result.ruby_object, 0, result.stdout, result.stderr]
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

        # @param [String] path Path to the directory to list its contents.  If no
        #   path given, lists the current working directory.
        #
        # @return [Array<Rosh::RemoteBase>, Rosh::ErrorENOENT] On
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

              return [error, result.exit_status, result.stdout, result.stderr]
            end

            return([]) if result.ruby_object.nil?

            listing = result.ruby_object.split.map do |entry|
              full_path = "#{base}/#{entry}"
              good_info full_path

              Rosh::FileSystem.create(full_path, @host_name)
            end.compact

            [listing, 0, result.stdout, result.stderr]
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
              processes = list.find_all { |i| i.command =~ /\b#{name}\b/ }
              processes.each(&method(:ap))

              [processes, 0, result.stdout, result.stderr]
            elsif pid
              processes = list.find_all { |i| i.pid == pid }
              processes.each(&method(:ap))

              [processes, 0, result.stdout, result.stderr]
            else
              ap list

              [list, 0, result.stdout, result.stderr]
            end
          end
        end
      end
    end
  end
end
