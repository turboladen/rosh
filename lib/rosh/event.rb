class Rosh
  class Event < Struct.new(:event, :attribute, :cmd_result, :as_sudo, :changed_hash)
    # @!attribute [rw] event

    # @!attribute [rw] attribute
    #   The attribute of the object that changed.
    #   @return [Symbol]

    # @!attribute [rw] cmd_result

    # @!attribute [rw] as_sudo
    #   Was the command executed while runing via `sudo`?
    #   @return [Boolean]

    # @!attribute [rw] changed_hash
  end
end
