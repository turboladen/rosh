class Rosh
  class LocalFileSystemObject
    FileTest.singleton_methods.each do |meth|
      if meth == :identical?
        define_method(:identical_to?) do |other_file|
          FileTest.identical?(@path, other_file)
        end
      else
        define_method(meth) do
          FileTest.send(meth, @path)
        end
      end
    end

    def self.create(path)
      fso = new(path)

      if fso.directory?
        Rosh::LocalDir.new(path)
      elsif fso.file?
        Rosh::LocalFile.new(path)
      elsif fso.symlink?
        Rosh::LocalLink.new(path)
      end
    end

    def initialize(path)
      @path = path
    end

    def to_path
      @path
    end
  end
end

require_relative 'local_dir'
require_relative 'local_file'
require_relative 'local_link'
