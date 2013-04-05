require 'open-uri'
require 'sys/proctable'
require_relative 'command_result'
require_relative 'local_file_system_object'


class Rosh
  class LocalShell
    def initialize
      @internal_pwd = Dir.new(Dir.pwd)
    end

    # @return [Rosh::CommandResult] On success, #exit_status is 0, #ruby_object
    #   is the contents of the file as a String.  On fail, #exit_status is 1,
    #   #ruby_object is the Exception that was raised.
    def cat(file)
      file = preprocess_path(file)

      begin
        contents = open(file).read
        Rosh::CommandResult.new(contents, 0)
      rescue Errno::ENOENT, Errno::EISDIR => ex
        Rosh::CommandResult.new(ex, 1)
      end
    end

    # @param [String] path The absolute or relative path to make the new working
    #   directory.
    # @return [Rosh::CommandResult] On success, #exit_status is 0, #ruby_object
    #   is the new directory as a Dir.  On fail, #exit_status is 1,
    #   #ruby_object is the Exception that was raised.
    def cd(path)
      path = preprocess_path(path)

      begin
        Dir.chdir(path)
        @internal_pwd = Dir.new(Dir.pwd)
        Rosh::CommandResult.new(@internal_pwd, 0)
      rescue Errno::ENOENT, Errno::ENOTDIR => ex
        Rosh::CommandResult.new(ex, 1)
      end
    end

    # @param [String] source The path to the file to copy.
    # @param [String] destination The destination to copy the file to.
    # @return [Rosh::CommandResult] On success, #exit_status is 0, #ruby_object
    #   is +true+.  On fail, #exit_status is 1, #ruby_object is the Exception
    #   that was raised.
    def cp(source, destination)
      source = preprocess_path(source)
      destination = preprocess_path(destination)

      begin
        FileUtils.cp(source, destination)
        Rosh::CommandResult.new(true, 0)
      rescue Errno::ENOENT, Errno::EISDIR => ex
        Rosh::CommandResult.new(ex, 1)
      end
    end

    # @param [String] command The system command to execute.
    # @return [Rosh::CommandResult] On success, #exit_status is 0, #ruby_object
    #   is the output of the command as a String.  On fail, #exit_status is 1,
    #   #ruby_object is +nil+.
    def exec(command)
      result = system(command)
      status = result ? 0 : 1

      Rosh::CommandResult.new(result, status)
    end

    # @param [String] path Path to the directory to list its contents.
    # @return [Rosh::CommandResult] On success, #exit_status is 0, #ruby_object
    #   is an Array of Rosh::LocalFileSystemObjects.  On fail, #exit_status is
    #   1, #ruby_object is a Errno::ENOENT.
    def ls(path=nil)
      path = preprocess_path(path)

      begin
        fso_array = Dir.entries(path).map do |entry|
          Rosh::LocalFileSystemObject.create("#{path}/#{entry}")
        end

        Rosh::CommandResult.new(fso_array, 0)
      rescue Errno::ENOENT, Errno::ENOTDIR => ex
        Rosh::CommandResult.new(ex, 1)
      end
    end

    # @return [Rosh::CommandResult] #exit_status is 0, #ruby_object is the
    #   current working directory as a Dir.
    def pwd
      Rosh::CommandResult.new(@internal_pwd, 0)
    end

    # @return [Rosh::CommandResult] #exit_status is 0, #ruby_object is an Array
    #   of Struct::ProcTableStructs.  See https://github.com/djberg96/sys-proctable
    #   for more info.
    def ps
      Rosh::CommandResult.new(Sys::ProcTable.ps, 0)
    end

    # @param [String] code The Ruby code to execute.
    # @return [Rosh::CommandResult] If the Ruby code raises an exception,
    #   #exit_status will be 1 and #ruby_object will be the exception that was
    #   raised.  If no exception was raised, #exit_status will be 0 and
    #   #ruby_object will be the object returned from the code that was executed.
    def ruby(code)
      status = 0

      result = begin
        code.gsub!(/puts/, '$stdout.puts')
        get_binding.eval(code)
      rescue => ex
        status = 1
        ex
      end

      Rosh::CommandResult.new(result, status)
    end

    private

    def preprocess_path(path)
      path = '' unless path
      path.strip!

      File.expand_path(path)
    end

    # @return [Binding] Binding to use for executing Ruby code in.
    def get_binding
      @binding ||= eval('private; binding',
        TOPLEVEL_BINDING,
        __FILE__,
        __LINE__ - 3)
    end
  end
end
