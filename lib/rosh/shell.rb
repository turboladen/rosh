require 'open-uri'
require 'abbrev'
require 'fileutils'
require 'log_switch'
require 'sys/proctable'
require_relative 'file'
require_relative 'directory'


class Rosh
  class Shell
    extend LogSwitch
    include LogSwitch::Mixin

    attr_reader :pwd

    def initialize
      @pwd = Dir.pwd
    end

    # @return [Array<Symbol>] List of commands supported by the shell.
    def commands
      return @commands if @commands

      @commands = public_methods.sort - Object.new.public_methods
      @commands.delete(:commands)
      @commands.delete(:command_abbrevs)

      @commands
    end

    # @return [Hash] Abbreviations to use for command completion.
    def command_abbrevs
      require 'ap'
      hash = commands.map(&:to_s).abbrev

      children = Dir["#{@pwd}/*"].map { |f| ::File.basename(f) }
      hash.merge! children.abbrev

      all_children = children.map { |c| Dir["#{c}/**/*"] }.flatten
      hash.merge! all_children.abbrev

      hash
    end

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

      r
    end

    # @return [Hash{Fixnum => Struct::ProcTableStruct}]
    def ps
      Sys::ProcTable.ps.inject({}) do |result, p|
        result[p.pid] = p

        result
      end
    end

    def cd(path)
      begin
        FileUtils.chdir path
        @pwd = FileUtils.pwd
      rescue Errno::ENOENT => ex
        puts ex.message.red
      end
    end

    # @params [String] file The filename.
    # @return [String] The file contents.
    def cat(file)
      begin
        contents = open(file).read
      rescue Errno::ENOENT, Errno::EISDIR => ex
        puts ex.message.red
      end

      contents
    end

    def history
      Readline::HISTORY.to_a.each_with_index do |cmd, i|
        puts "  #{i}  #{cmd}"
      end
    end

    def cp(source, destination)
      FileUtils.cp(source, destination)
    end

    def reload!
      load __FILE__
    end

    def ruby(code)
      code.gsub!(/puts/, '$stdout.puts')
      get_binding.eval(code)
    end

    private

    def get_binding
      @binding ||= binding
    end
  end
end
