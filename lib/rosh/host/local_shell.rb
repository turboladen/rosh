require 'irb'
require 'open-uri'
require 'sys/proctable'
require 'fileutils'
require 'shellwords'
require 'pty'

require 'log_switch'
require 'highline/import'
require_relative '../command_result'
require_relative 'local_file_system_object'


class Rosh
  class Host

    # Throws :shell_failure if it was initialized with +throw_on_fail+ true.
    class LocalShell
      extend LogSwitch
      include LogSwitch::Mixin

      attr_reader :history
      attr_reader :workspace

      def initialize(throw_on_fail)
        @history = []
        @throw_on_fail = throw_on_fail
      end

      # @param [String] file Path to the file to cat.
      #
      # @return [String] On success, returns the contents of the file as a String.
      #   On fail, #last_exit_status is set to 1 and returns the Exception that
      #   was raised.
      def cat(file)
        log "cat called with arg '#{file}'"
        full_file = preprocess_path(file)

        process(:cat, file: file) do
          begin
            contents = open(full_file).read
            [contents, 0]
          rescue Errno::ENOENT, Errno::EISDIR => ex
            [ex, 1]
          end
        end
      end

      # @param [String] path The absolute or relative path to make the new working
      #   directory.
      #
      # @return [TrueClass] On success, returns true.  On fail,
      #   #last_exit_status is set to 1 and returns the Exception that was raised.
      def cd(path)
        log "cd called with arg '#{path}'"
        full_path = preprocess_path(path)

        process(:cd, path: path) do
          begin
            Dir.chdir(full_path)
            ENV['PWD'] = Dir.pwd
            [true, 0]
          rescue Errno::ENOENT, Errno::ENOTDIR => ex
            [ex, 1]
          end
        end
      end

      # @param [String] source The path to the file to copy.
      # @param [String] destination The destination to copy the file to.
      #
      # @return [TrueClass] On success, returns +true+.  On fail, #last_exit_status
      #   is set to 1 and returns the Exception that was raised.
      def cp(source, destination)
        log "cp called with args '#{source}', '#{destination}'"
        full_source = preprocess_path(source)
        full_destination = preprocess_path(destination)

        process(:cp, source: source, destination: destination) do
          begin
            ::FileUtils.cp(full_source, full_destination)
            [true, 0]
          rescue Errno::ENOENT, Errno::EISDIR => ex
            [ex, 1]
          end
        end
      end

      # The shell's environment.  Note this doesn't trump the Ruby process's ENV
      # settings (which are still accessible).
      #
      # @return [Hash] A Hash containing the environment info.
      def env
        log 'env called'

        process(:env) do
          @path ||= ENV['PATH'].split(':')

          env = {
            path: @path,
            shell: File.expand_path(File.basename($0), File.dirname($0)),
            pwd: pwd.to_path
          }

          [env, 0]
        end
      end

      # @param [String] command The system command to execute.
      #
      # @return [String] On success, returns the output of the command.  On
      #   fail, #last_exit_status is whatever was set by the command and returns
      #   the exception that was raised.
      def exec(command)
        log "exec called with command '#{command}'"
        #cmd, *args = Shellwords.shellsplit(command)

        process(:exec, command: command) do
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

      # @param [Integer] status Exit status code.
      def exit(status=0)
        Kernel.exit(status)
      end

      # @param [String] path Path to the directory to list its contents.  If no
      #   path given, lists the current working directory.
      #
      # @return [Array<Rosh::LocalFileSystemObject>] On success, returns an
      #   Array of Rosh::LocalFileSystemObjects.  On fail, #last_exit_status is
      #   1 and returns a Errno::ENOENT or Errno::ENOTDIR.
      def ls(path=nil)
        log "ls called with arg '#{path}'"
        full_path = preprocess_path(path)

        process(:ls, path: path) do
          if File.file? full_path
            fso = Rosh::Host::LocalFileSystemObject.create(full_path)
            [fso, 0]
          else
            begin
              fso_array = Dir.entries(full_path).map do |entry|
                Rosh::Host::LocalFileSystemObject.create("#{full_path}/#{entry}")
              end

              [fso_array, 0]
            rescue Errno::ENOENT, Errno::ENOTDIR => ex
              [ex, 1]
            end
          end
        end
      end

      # @param [String] name The name of a command to filter on.
      # @param [Integer] pid The pid of a command to find.
      #
      # @return [Array<Struct::ProcTableStruct>, Struct::ProcTableStruct] When
      #   no options are given, all processes returned.  When +:name+ is given,
      #   an Array of processes that match COMMAND are given.  When +:pid+ is
      #   given, a single process is returned.  See https://github.com/djberg96/sys-proctable
      #   for more info.
      def ps(name: nil, pid: nil)
        log "ps called with args 'name: #{name}', 'pid: #{pid}'"

        process(:ps, name: name, pid: pid) do
          ps = Sys::ProcTable.ps

          if name
            p = ps.find_all { |i| i.cmdline =~ /\b#{name}\b/ }
            [p, 0]
          elsif pid
            p = ps.find { |i| i.pid == pid }
            [p, 0]
          else
            [ps, 0]
          end
        end
      end

      # @return [Dir] The current working directory as a Dir.
      def pwd
        log 'pwd called'
        process(:pwd) { [Dir.new(ENV['PWD']), 0] }
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
          rescue Exception => ex
            [ex, 1]
          end
        end
      end

      # @return [Array<String>] List of commands given in the PATH.
      def system_commands
        env[:path].map do |dir|
          Dir["#{dir}/*"].map { |f| ::File.basename(f) }
        end.flatten
      end

      def last_result
        @history.last[:output]
      end
      alias :__ :last_result

      # @return [Integer] Shortcut to the result of the last command executed.
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

      # Saves the result of the block given to #last_result and exit code to
      # #last_exit_status.
      #
      # @param [Array<String>, String] args Arguments given to the method.
      #
      # @return The result of the block that was given.
      def process(cmd, **args, &block)
        last_result, last_exit_status = block.call

        @history << {
          command: cmd,
          arguments: args,
          output: last_result,
          exit_status: last_exit_status
        }

        if @throw_on_fail && !last_exit_status.zero?
          throw(:shell_failure, @history.last)
        end

        last_result
      end

      # Expands paths based on the context of the shell.  Allows for using Ruby
      # to pass in a path (via eval).
      #
      # @param [] path A String or some Ruby code that will eval to represent a
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
