require 'irb'
require 'fileutils'
require 'shellwords'
require 'pty'

require 'awesome_print'

require_relative 'base'
require_relative '../../file_system/directory'
require_relative '../wrapper_methods/local'


class Rosh
  class Host
    module Shells
      class Local < Base
        extend LogSwitch
        include LogSwitch::Mixin
        include WrapperMethods::Local

        attr_reader :workspace

        # @param [String] output_commands Toggle for outputting all commands
        #   that were executed.  Note that some operations comprise of multiple
        #   commands.
        def initialize(output_commands=true)
          super(output_commands)
          @internal_pwd = Dir.pwd
        end

        # @param [String] path The absolute or relative path to make the new working
        #   directory.
        #
        # @return [TrueClass] On success, returns true.  On fail,
        #   #last_exit_status is set to 1 and returns the Exception that was
        #   raised.
        def cd(path)
          log "cd called with arg '#{path}'"
          full_path = preprocess_path(path)

          process(:cd, path: path) do
            begin
              Dir.chdir(full_path)
              @internal_pwd = Dir.pwd

              [true, 0]
            rescue Errno::ENOENT, Errno::ENOTDIR => ex
              [ex, 1]
            end
          end
        end

        # Prints and returns the shell's environment as a command.  Note this
        # doesn't trump the Ruby process's ENV settings (which are still
        # accessible).
        #
        # @return [Hash] A Hash containing the environment info.
        def env
          log 'env called'

          process(:env) do
            env = _env
            ap env

            [env, 0]
          end
        end

        # The shell's environment as a Hash.  Does not alter the state of the
        # shell.
        #
        # @return [Hash]
        def _env
          @path ||= ENV['PATH'].split(':')

          {
            path: @path,
            shell: File.expand_path(File.basename($0), File.dirname($0)),
            pwd: _pwd.to_path
          }
        end

        # @param [String] command The system command to execute.
        #
        # @return [String] On success, returns the output of the command.  On
        #   fail, #last_exit_status is whatever was set by the command and returns
        #   the exception that was raised.
        def exec(command)
          command = command.insert(0, 'sudo ') if @sudo
          log "exec called with command '#{command}'"
          #cmd, *args = Shellwords.shellsplit(command)

          process(:exec, command: command) do
            run_info(command) if @output_commands

            begin
              output = ''

              #PTY.spawn(cmd, *args) do |reader, writer, pid|
              PTY.spawn(command) do |reader, writer, pid|
                log "Spawned pid: #{pid}"

                trap(:INT) do
                  Process.kill(:INT, pid)
                end

                $stdout.sync
                STDIN.sync

                begin
                  while buf = reader.readpartial(1024)
                    output << buf
                    $stdout.print buf

                    if output.match /Password:$/
                      password = ask('') { |q| q.echo = false }
                      writer.puts password
                    end
                  end
                rescue EOFError
                  log "Done reading for pid #{pid}"
                end

                Process.wait(pid)
              end

              [output, $?.exitstatus]
            rescue => ex
              [ex, 1]
            end
          end
        end

        # @return [Dir] The current working directory as a Dir.
        def pwd
          log 'pwd called'

          output = process(:pwd) { [_pwd, 0] }
          puts File.expand_path(output)

          output
        end

        # @return [Rosh::Host::FileSystem::Directory] Returns the current
        #   working directory, but doesn't alter state of the shell (i.e. does
        #   not alter last_exit_status, etc).
        def _pwd
          Rosh::Host::FileSystem::Directory.new(@internal_pwd, @host_name)
        end

        # Executes Ruby code in the context of an IRB::WorkSpace.  Thus, variables
        # are maintained across calls to this.
        #
        # @param [String] code The Ruby code to execute.
        #
        # @return [] If the Ruby code raises an exception,
        #   #last_exit_status will be 1 and will return the exception that was
        #   raised.  If no exception was raised, this will return the returned
        #   object from the code that was executed.
        def ruby(code)
          log "ruby called with code: #{code}"

          process(:ruby, code: code) do
            code.gsub!(/puts/, '$stdout.puts')
            path_info = code.scan(/\s(?<fs_path>\/[^\n]*\/?)$/).flatten

            if $~
              code.gsub!(/#{$~[:fs_path]}/, %["#{path_info.first}"])
            end

            retried = false

            begin
              @workspace ||= IRB::WorkSpace.new(binding)
              log 'Running Ruby code:'
              log code
              r = @workspace.evaluate(binding, code)

              [r, 0]
            rescue NoMethodError => ex
              %r[undefined method `(?<meth>[^']+)] =~ ex.message
              log "NoMethodError for: #{meth}"

              if retried
                raise ex
              else
                code = fix_no_method(meth, code)
                retried = true
                retry
              end
            rescue StandardError => ex
              [ex, 1]
            end
          end
        end

        # @return [Array<String>] List of commands given in the PATH.
        def system_commands
          _env[:path].map do |dir|
            Dir["#{dir}/*"].map { |f| ::File.basename(f) }
          end.flatten
        end

        #-----------------------------------------------------------------------
        # PRIVATES
        #-----------------------------------------------------------------------
        private

        # Expands paths based on the context of the shell.  Allows for using Ruby
        # to pass in a path (via eval).
        #
        # @param path A String or some Ruby code that will eval to represent a
        #   path.
        #
        # @return [String] Fully expanded path of the given path.
        def preprocess_path(path)
          path = '' unless path
          path.strip!

          path = unless File.exists? path
            begin
              instance_eval(path)
            rescue NameError, SyntaxError
            end
          end || path

          File.expand_path(path)
        end

        def fix_no_method(meth, code, arg=nil)
          exec_matcher = %r[#{meth} (?<args>.*)]
          code =~ exec_matcher
          args = $~[:args]

          output = if args.nil? || args.empty?
            if arg
              exec("#{meth} #{arg}")
            else
              exec("#{meth}")
            end
          else
            exec("#{meth} #{args}")
          end

          code.sub(exec_matcher, %["#{output}"])
        end
      end
    end
  end
end
