require_relative '../errors'


class Rosh
  class Shell

    # Commands are all processed within a #process block.  Each command is
    # expected to return an Array of three values: [return_value, exit_status,
    # ssh_output].
    #
    module Commands

      # @param [String] file The path of the file to cat.
      #
      # @return [String, ROSH::ErrorNOENT] On success, returns the contents of
      #   the file as a String.  On fail, #last_exit_status is set to the exit
      #   status from the remote command, and a Rosh::ErrorNOENT error is
      #   returned.
      def cat(file)
        echo_rosh_command file

        process(:cat, file: file) do
          begin
            output = current_host.fs[file: file].contents

            [output, 0]
          rescue Rosh::ErrorENOENT => ex
            [ex, 127]
          end
        end
      end

      def cd(path)
        echo_rosh_command path

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
        echo_rosh_command source, destination

        process(:cp, source: source, destination: destination) do
          current_host.fs[source].copy_to(destination)
        end
      end

      # Prints and returns the shell's environment as a command.  Note this
      # doesn't trump the Ruby process's ENV settings (which are still
      # accessible).
      #
      # @return [Hash] A Hash containing the environment info.
      def env
        echo_rosh_command

        process(:env) do
          _env = env_internal

          private_result(_env, 0)
        end
      end

      def env_internal
        adapter

        @path ||= ENV['PATH'].split ':'

        {
          path: @path,
          shell: ::File.expand_path(::File.basename($0), ::File.dirname($0)),
          pwd: @internal_pwd
        }
      end

      def exec(command)
        echo_rosh_command command

        process(:exec, command) do
          exec_internal(command)
        end
      end

      # Use for running #exec, but without updating the host's history.
      #
      # @param [String] command
      # @return [Rosh::Shell::PrivateCommandResult]
      def exec_internal(command)
        @history << adapter.exec(command, @internal_pwd)
      end

      def lh
        echo_rosh_command

        process(:lh) do
          [Rosh.hosts.keys.each(&method(:puts)), 0]
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
        echo_rosh_command path

        process(:ls, path: path) do
          path ||= '.'
          full_path = adapter.preprocess_path(path, @internal_pwd)

          begin
            list = current_host.fs[full_path].list
            ap list

            [list, 0]
          rescue Rosh::ErrnoENOENT, Errno::ENOENT, Errno::ENOTDIR => ex
            error = Rosh::ErrorENOENT.new(result.stderr)

            [error, 127]
          end
        end
      end

      def ps(name: nil, pid: nil)
        echo_rosh_command name, pid

        process(:ps, name: name, pid: pid) do
          list = current_host.processes.list(name: name, pid: pid)

          [list, 0, nil]
        end
      end

      def pwd
        echo_rosh_command

        process(:pwd) do
          private_result(pwd_internal, 0)
        end
      end

      def pwd_internal
        adapter

        @internal_pwd
      end

      def ruby(code)
        echo_rosh_command code

        process(:ruby, code: code) do
          adapter.ruby(code)
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
