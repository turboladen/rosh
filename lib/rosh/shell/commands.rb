require_relative '../errors'
require_relative 'private_command_result'

class Rosh
  class Shell
    # Commands are all processed within a #process block.  Each command is
    # expected to return an Array of three values: [return_value, exit_status,
    # ssh_output].
    #
    module Commands
      # @param [String] file The path of the file to cat.
      #
      # @return [String, Rosh::ErrorENOENT, Rosh::ErrorEISDIR] On success, returns the contents of
      #   the file as a String.  On fail, #last_exit_status is set to the exit
      #   status from the remote command, and a Rosh::ErrorNOENT error is
      #   returned.
      def cat(file)
        echo_rosh_command file

        process(:cat, file) do
          current_host.fs[file: file].contents
        end
      end

      def cd(path)
        echo_rosh_command path

        process(:cd, path) do
          full_path = adapter.preprocess_path(path, @internal_pwd)
          log %(cd full path '#{full_path}')

          cmd_result = adapter.cd(full_path)
          @internal_pwd = full_path if last_exit_status.zero?

          cmd_result
        end
      end

      def cp(source, destination)
        echo_rosh_command source, destination

        process(:cp, source, destination) do
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
          shell: ::File.expand_path(::File.basename($PROGRAM_NAME), ::File.dirname($PROGRAM_NAME)),
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
        # TODO: Do I want to add this to the history??
        result = adapter.exec(command, @internal_pwd)
        @history << result

        result
      end

      def lh
        echo_rosh_command

        process(:lh) do
          list = Rosh.hosts.keys.map(&:to_s)

          private_result(list, 0, list.join("\n"))
        end
      end

      # @param [String] path Path to the directory to list its contents.  If no
      #   path given, lists the current working directory.
      #
      # @return [Array<Rosh::RemoteBase>, Rosh::ErrorENOENT] On
      #   success, returns an Array of Rosh::RemoteFileSystemObjects.  On fail,
      #   #last_exit_status is set to the status given by the remote host's
      #   failed 'ls' command, returns a Rosh::ErrorENOENT.
      def ls(path = nil, color: false)
        echo_rosh_command path

        process(:ls, path, color: color) do
          path ||= '.'
          full_path = adapter.preprocess_path(path, @internal_pwd)
          cmd_result = current_host.fs[full_path].list

          cmd_result.string = cmd_result.string.yellow if color

          cmd_result
        end
      end

      def ps(name: nil, pid: nil)
        echo_rosh_command name, pid

        process(:ps, name: name, pid: pid) do
          current_host.processes.list(name: name, pid: pid)
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

        process(:ruby, code) do
          adapter.ruby(code)
        end
      end

      #       private
      #
      #       # Saves the result of the block given to #last_result and exit code to
      #       # #last_exit_status.
      #       #
      #       # @param [Array<String>, String] args Arguments given to the method.
      #       #
      #       # @return The result of the block that was given.
      #       def process(cmd, **args, &block)
      #
      #         result_object, exit_status, ssh_output = block.call
      #
      #         @history << {
      #           time: Time.now.to_s,
      #           command: cmd,
      #           arguments: args,
      #           output: result,
      #           exit_status: exit_status,
      #           ssh_output: ssh_output
      #         }
      #         #@history << CommandResult.new(cmd, args, result_object, exit_status,
      #         #  ssh_output: ssh_output)
      #
      #
      #         @history.last[:output]
      #
      #         private_result = block.call
      #
      #         @history << {
      #           time: private_result.executed_at,
      #           command: cmd,
      #           arguments: args,
      #           output: private_result.ruby_object,
      #           exit_status: private_result.exit_status
      #         }
      #
      #         @history.last[:output]
      #       end
    end
  end
end
