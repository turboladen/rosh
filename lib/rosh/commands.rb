require 'open-uri'
require 'fileutils'
require 'sys/proctable'
require_relative 'file'
require_relative 'directory'


class Rosh
  module Commands

    # @return [Hash{String => Rosh::File,Rosh::Directory}] Each file or directory in the
    #   given path.
    def ls(path='')
      path.strip!
      path = path.empty? ? './*' : path
      path = path.end_with?('/*') ? path : "#{path}/*"

      r = {}
      Dir[path].map do |file|
        new_file = if ::File.directory? file
          Rosh::Directory.new file
        elsif ::File.file? file
          Rosh::File.new(file)
        end

        r[file] = new_file
      end

      [0, r]
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
      code.gsub!(/puts/, '$stdout.puts')
      get_binding.eval(code)
    end
  end
end
