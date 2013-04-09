class Rosh
  class ErrorENOENT < StandardError
  end

  class ErrorEISDIR < StandardError
  end

  class UnrecognizedService < StandardError
  end

  class InaccessiblePIDFile < StandardError
  end

  class PermissionDenied < StandardError
  end
end
