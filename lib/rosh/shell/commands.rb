class Rosh
  class Shell

    # Commands are all processed within a #process block.  Each command is
    # expected to return an Array of three values: [return_value, exit_status,
    # ssh_output].
    #
    module Commands
      def cat(file)
        process(:cat, file: file) do
          adapter.cat(file)
        end
      end

      def cd(path)
        full_path = adapter.preprocess_path(path, @internal_pwd)
        log %[cd full path '#{full_path}']

        result = process(:cd, path: path) do
          adapter.cd(full_path)
        end

        if last_exit_status.zero?
          @internal_pwd = full_path
        end

        result
      end

      def cp(source, destination)
        process(:cp, source: source, destination: destination) do
          adapter.cp(source, destination)
        end
      end

      # Prints and returns the shell's environment as a command.  Note this
      # doesn't trump the Ruby process's ENV settings (which are still
      # accessible).
      #
      # @return [Hash] A Hash containing the environment info.
      def env
        adapter

        @path ||= ENV['PATH'].split ':'

        process(:env) do
          _env = {
            path: @path,
            shell: ::File.expand_path(::File.basename($0), ::File.dirname($0)),
            pwd: @internal_pwd
          }

          ap _env

          [_env, 0]
        end
      end

      def exec(command)
        process(:exec, command: command) do
          adapter.exec(command, @internal_pwd)
        end
      end

      def lh
        process(:lh) do
          [Rosh.hosts.keys.each(&method(:puts)), 0]
        end
      end

      def ls(path=nil)
        process(:ls, path: path) do
          path ||= '.'
          full_path = adapter.preprocess_path(path, @internal_pwd.to_path)
          adapter.ls(full_path)
        end
      end

      def ps(name: nil, pid: nil)
        process(:ps, name: name, pid: pid) do
          list = current_host.processes.list(name: name, pid: pid)

          [list, 0, nil]
        end
      end

      def pwd
        adapter

        _pwd = Rosh::FileSystem::Directory.new(@internal_pwd, @host_name)

        process(:pwd) do
          [_pwd, 0, nil]
        end

        puts _pwd.to_path

        _pwd
      end

      def ruby(code)
        process(:ruby, code: code) do
          adapter.ruby(code)
        end
      end

      def system_commands
        process(:system_commands) do
          adapter.system_commands
        end
      end

      private

      # Saves the result of the block given to #last_result and exit code to
      # #last_exit_status.
      #
      # @param [Array<String>, String] args Arguments given to the method.
      #
      # @return The result of the block that was given.
      def process(cmd, **args, &block)
        result, exit_status, ssh_output = block.call

        @history << {
          time: Time.now.to_s,
          command: cmd,
          arguments: args,
          output: result,
          exit_status: exit_status,
          ssh_output: ssh_output
        }

        @history.last[:output]
      end
    end
  end
end
