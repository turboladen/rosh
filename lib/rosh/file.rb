require 'delegate'


class Rosh
  class File < DelegateClass(::File)
    attr_reader :path

    def initialize(path)
      @path = path
      super(path)
    end

    def content
      @content ||= ::File.read(@path)
    end

    def content=(new_content)
      ::File.write(new_content)
      @content = new_content
    end

    def to_s
      @path
    end

    def exists?
      ::File.exist?(@path)
    end

    def mode
      ::File.stat(@path).mode.to_s(8)
    end
  end
end
