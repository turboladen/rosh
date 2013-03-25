class Rosh
  class Directory
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def to_s
      @path
    end

    def exists?
      ::File.exist? @path
    end

    def mode
      ::File.stat(@path).mode.to_s(8)
    end
  end
end
