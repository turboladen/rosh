require 'irb'
require 'pty'
require 'log_switch'
require 'awesome_print'
require 'sys/proctable'


class Rosh
  class Shell
    module Adapters
      module Local
        extend LogSwitch
        include LogSwitch::Mixin

        def cat(file)
          File.read(file)
        end

        # @param [String] path The absolute or relative path to make the new working
        #   directory.
        #
        # @return [TrueClass] On success, returns true.  On fail,
        #   #last_exit_status is set to 1 and returns the Exception that was
        #   raised.
        def cd(path)
          begin
            Dir.chdir(path)
            @internal_pwd = Dir.pwd

            [true, 0]
          rescue Errno::ENOENT, Errno::ENOTDIR => ex
            bad_info "No such file or directory: #{path}"
            [ex, 1]
          end
        end

        # @param [String] command The system command to execute.
        #
        # @return [String] On success, returns the output of the command.  On
        #   fail, #last_exit_status is whatever was set by the command and returns
        #   the exception that was raised.
        def exec(command, _=nil)
          run_info(command)# if @output_commands

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
            bad_info "#{ex}"
            [ex, 1]
          end
        end

        # @param [String] path Path to the directory to list its contents.  If no
        #   path given, lists the current working directory.
        #
        # @return [Array<Rosh::Host::Adapters::LocalBase>] On success, returns an
        #   Array of Rosh::Host::FileSystemObjects.  On fail, #last_exit_status is
        #   1 and returns a Errno::ENOENT or Errno::ENOTDIR.
        def ls(path)
          begin
            list = current_host.fs[path].list

            [list, 0]
          rescue Errno::ENOENT, Errno::ENOTDIR => ex
            [ex, 1]
          end
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

        # @return [Array<String>] List of commands given in the PATH.
        def system_commands
          _env[:path].map do |dir|
            Dir["#{dir}/*"].map { |f| ::File.basename(f) }
          end.flatten
        end

        # Expands paths based on the context of the shell.  Allows for using Ruby
        # to pass in a path (via eval).
        #
        # @param path A String or some Ruby code that will eval to represent a
        #   path.
        #
        # @return [String] Fully expanded path of the given path.
        def preprocess_path(path, internal_pwd)
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

        #-----------------------------------------------------------------------
        # PRIVATES
        #-----------------------------------------------------------------------
        private

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
