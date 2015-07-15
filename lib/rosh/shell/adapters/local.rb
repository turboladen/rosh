require 'irb'
require 'pty'
require 'awesome_print'
require 'sys/proctable'
require_relative '../../kernel_refinements'
require_relative '../../logger'

class Rosh
  class Shell
    module Adapters
      module Local
        include Rosh::Logger

        # @param [String] path The absolute or relative path to make the new working
        #   directory.
        #
        # @return [TrueClass] On success, returns true.  On fail,
        #   #last_exit_status is set to 1 and returns the Exception that was
        #   raised.
        def cd(path)
          Dir.chdir(path)
          @internal_pwd = Dir.pwd

          private_result(true, 0)
        rescue Errno::ENOENT
          ex = Rosh::ErrorENOENT.new(path)
          private_result(ex, 1, ex.message)
        rescue Errno::ENOTDIR
          ex = Rosh::ErrorENOTDIR.new(path)
          private_result(ex, 1, ex.message)
        end

        # @param [String] command The system command to execute.
        #
        # @return [String] On success, returns the output of the command.  On
        #   fail, #last_exit_status is whatever was set by the command and returns
        #   the exception that was raised.
        def exec(command, _ = nil)
          run_info(command) # if @output_commands

          begin
            output = ''

            # PTY.spawn(cmd, *args) do |reader, writer, pid|
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

            private_result(output, $CHILD_STATUS.exitstatus)
          rescue => ex
            private_result(ex, 1, ex.message)
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

          code.gsub!(/#{$LAST_MATCH_INFO[:fs_path]}/, %("#{path_info.first}")) if $LAST_MATCH_INFO

          retried = false

          begin
            @workspace ||= IRB::WorkSpace.new(binding)
            log 'Running Ruby code:'
            log code
            r = @workspace.evaluate(binding, code)

            private_result(r, 0, r.to_s)
          rescue NoMethodError => ex
            /undefined method `(?<meth>[^']+)/ =~ ex.message
            log "NoMethodError for: #{meth}"

            if retried
              private_result(ex, 1, ex.message)
            else
              code = fix_no_method(meth, code)
              retried = true
              retry
            end
          rescue StandardError => ex
            private_result(ex, 1, ex.message)
          end
        end

        # Expands paths based on the context of the shell.  Allows for using Ruby
        # to pass in a path (via eval).
        #
        # @param path A String or some Ruby code that will eval to represent a
        #   path.
        #
        # @return [String] Fully expanded path of the given path.
        def preprocess_path(path, _internal_pwd)
          path = '' unless path
          path.strip!

          path = unless File.exist? path
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

        def fix_no_method(meth, code, arg = nil)
          exec_matcher = /#{meth} (?<args>.*)/
          code =~ exec_matcher
          args = $LAST_MATCH_INFO[:args]

          output = if args.nil? || args.empty?
                     if arg
                       exec("#{meth} #{arg}")
                     else
                       exec("#{meth}")
                     end
                   else
                     exec("#{meth} #{args}")
          end

          code.sub(exec_matcher, %("#{output}"))
        end
      end
    end
  end
end
