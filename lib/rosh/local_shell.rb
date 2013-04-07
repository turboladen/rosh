require 'irb'
require 'open-uri'
require 'sys/proctable'
require_relative 'command_result'
require_relative 'local_file_system_object'


class Rosh
  class LocalShell
    attr_reader :last_result

    def initialize
      @internal_pwd = Dir.new(Dir.pwd)
      @last_result = Rosh::CommandResult.new(nil, 0)
    end

    # @return [Rosh::CommandResult] On success, #exit_status is 0, #ruby_object
    #   is the contents of the file as a String.  On fail, #exit_status is 1,
    #   #ruby_object is the Exception that was raised.
    def cat(file)
      process(file) do |full_file|
        begin
          contents = open(full_file).read
          Rosh::CommandResult.new(contents, 0)
        rescue Errno::ENOENT, Errno::EISDIR => ex
          Rosh::CommandResult.new(ex, 1)
        end
      end
    end

    # @param [String] path The absolute or relative path to make the new working
    #   directory.
    # @return [Rosh::CommandResult] On success, #exit_status is 0, #ruby_object
    #   is the new directory as a Dir.  On fail, #exit_status is 1,
    #   #ruby_object is the Exception that was raised.
    def cd(path)
      process(path) do |full_path|
        begin
          Dir.chdir(full_path)
          @internal_pwd = Dir.new(Dir.pwd)
          Rosh::CommandResult.new(@internal_pwd, 0)
        rescue Errno::ENOENT, Errno::ENOTDIR => ex
          Rosh::CommandResult.new(ex, 1)
        end
      end
    end

    # @param [String] source The path to the file to copy.
    # @param [String] destination The destination to copy the file to.
    # @return [Rosh::CommandResult] On success, #exit_status is 0, #ruby_object
    #   is +true+.  On fail, #exit_status is 1, #ruby_object is the Exception
    #   that was raised.
    def cp(source, destination)
      process(source, destination) do |full_source, full_destination|
        begin
          FileUtils.cp(full_source, full_destination)
          Rosh::CommandResult.new(true, 0)
        rescue Errno::ENOENT, Errno::EISDIR => ex
          Rosh::CommandResult.new(ex, 1)
        end
      end
    end

    # @param [String] command The system command to execute.
    # @return [Rosh::CommandResult] On success, #exit_status is 0, #ruby_object
    #   is the output of the command as a String.  On fail, #exit_status is 1,
    #   #ruby_object is +nil+.
    def exec(command)
      process do
        result = system(command)
        status = result ? 0 : 1

        Rosh::CommandResult.new(result, status)
      end
    end

    # @param [String] path Path to the directory to list its contents.
    # @return [Rosh::CommandResult] On success, #exit_status is 0, #ruby_object
    #   is an Array of Rosh::LocalFileSystemObjects.  On fail, #exit_status is
    #   1, #ruby_object is a Errno::ENOENT.
    def ls(path=nil)
      process(path) do |full_path|
        begin
          fso_array = Dir.entries(full_path).map do |entry|
            Rosh::LocalFileSystemObject.create("#{full_path}/#{entry}")
          end

          Rosh::CommandResult.new(fso_array, 0)
        rescue Errno::ENOENT, Errno::ENOTDIR => ex
          Rosh::CommandResult.new(ex, 1)
        end
      end
    end

    # @return [Rosh::CommandResult] #exit_status is 0, #ruby_object is the
    #   current working directory as a Dir.
    def pwd
      process { Rosh::CommandResult.new(@internal_pwd, 0) }
    end

    # @return [Rosh::CommandResult] #exit_status is 0, #ruby_object is an Array
    #   of Struct::ProcTableStructs.  See https://github.com/djberg96/sys-proctable
    #   for more info.
    def ps
      process { Rosh::CommandResult.new(Sys::ProcTable.ps, 0) }
    end

    # @param [String] code The Ruby code to execute.
    # @return [Rosh::CommandResult] If the Ruby code raises an exception,
    #   #exit_status will be 1 and #ruby_object will be the exception that was
    #   raised.  If no exception was raised, #exit_status will be 0 and
    #   #ruby_object will be the object returned from the code that was executed.
    def ruby(code)
      process do
        begin
          code.gsub!(/puts/, '$stdout.puts')
          @workspace ||= IRB::WorkSpace.new(binding)
          r = @workspace.evaluate(binding, code)
          r.is_a?(Rosh::CommandResult) ? r : Rosh::CommandResult.new(r, 0)
        rescue => ex
          Rosh::CommandResult.new(ex, 1)
        end
      end
    end

    # @return [Rosh::CommandResult] The result of the last command executed.  If
    #   no command has been executed, #ruby_object is nil; #exit_status is 0.
    def _?
      return @last_result if @last_result

      Rosh::CommandResult(nil, 0)
    end

    private

    def process(*paths, &block)
      @last_result = if paths.empty?
        block.call
      else
        full_paths = paths.map { |path| preprocess_path(path) }
        block.call(*full_paths)
      end
    end

    def preprocess_path(path)
      path = '' unless path
      path.strip!

      File.expand_path(path)
    end
  end
end
