class Rosh
  class ErrorENOENT < StandardError
    def initialize(path)
      msg = "File system object does not exist at path: #{path}"
      super(msg)
    end
  end

  class ErrorEEXIST < StandardError
    def initialize(path)
      msg = "File system object already exists at path: #{path}"
      super(msg)
    end
  end

  class ErrorEISDIR < StandardError
    def initialize(path)
      msg = "File system object is a directory: #{path}"
      super(msg)
    end
  end

  class ErrorENOTDIR < StandardError
    def initialize(path)
      msg = "File system object is not a directory: #{path}"
      super(msg)
    end
  end

  class UnrecognizedService < StandardError
  end

  class InaccessiblePIDFile < StandardError
  end

  class PermissionDenied < StandardError
  end

  class Shell
    class CommandNotFound < RuntimeError; end
  end
end
