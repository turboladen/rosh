require 'open-uri'
require 'fileutils'
require 'sys/proctable'
require_relative 'file'
require_relative 'directory'


class Rosh
  module Commands

    # @return [Hash{String => Rosh::File,Rosh::Directory}] Each file or directory in the
    #   given path.
    def ls(path=Dir.pwd)
      path.strip!
      status = 0
      r = {}

      begin
        Dir.entries(path).each do |entry|
          new_entry = if ::File.directory? "#{path}/#{entry}"
            Rosh::Directory.new "#{path}/#{entry}"
          elsif ::File.file? "#{path}/#{entry}"
            Rosh::File.new "#{path}/#{entry}"
          end

          r[entry] = new_entry
        end
      rescue Errno::ENOENT => ex
        status = 1
        r = { path => ex }
      end

      [status, r]
    end

    def pwd
      [0, @pwd]
    end

    # @return [Hash{Fixnum => Struct::ProcTableStruct}]
    def ps
      r = Sys::ProcTable.ps.inject({}) do |result, p|
        result[p.pid] = p

        result
      end

      [0, r]
    end

    def cd(path)
      begin
        FileUtils.chdir path
        @pwd = FileUtils.pwd
        [0, @pwd]
      rescue Errno::ENOENT => ex
        [1, ex.message.red]
      end
    end

    # @params [String] file The filename.
    # @return [String] The file contents.
    def cat(file)
      begin
        contents = open(file).read
        [0, contents]
      rescue Errno::ENOENT, Errno::EISDIR => ex
        [1, ex.message.red]
      end
    end

    def cp(source, destination)
      FileUtils.cp(source, destination)
    end

    def history
      lines = []

      Readline::HISTORY.to_a.each_with_index do |cmd, i|
        lines << "  #{i}  #{cmd}"
      end

      [0, lines]
    end

    def ruby(code)
      status = 0

      result = begin
        code.gsub!(/puts/, '$stdout.puts')
        get_binding.eval(code)
      rescue => ex
        status = 1
        ex
      end

      [status, result]
    end
  end
end
