require 'open-uri'
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
        ::Rosh::CommandResult.new(contents, 0)
      rescue Errno::ENOENT, Errno::EISDIR => ex
        ::Rosh::CommandResult.new(ex, 1)
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
        ::Rosh::CommandResult.new(@internal_pwd, 0)
      rescue Errno::ENOENT, Errno::ENOTDIR => ex
        ::Rosh::CommandResult.new(ex, 1)
      end
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
      ::Rosh::CommandResult.new(@internal_pwd, 0)
    end

    private

    def preprocess_path(path)
      path = '' unless path
      path.strip!

      File.expand_path(path)
    end
  end
end
