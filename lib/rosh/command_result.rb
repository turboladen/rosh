require 'json'
require 'yaml'
require 'net/ssh/simple'


class Rosh

  class CommandResult

    attr_accessor :exit_status

    attr_reader :ruby_object

    attr_reader :ssh_result

    def initialize(ruby_object, status=nil, ssh_result=nil)
      @exit_status = status
      @ruby_object = ruby_object
      @ssh_result = ssh_result

      if @ssh_result.is_a?(Net::SSH::Simple::Result) && @ruby_object.nil?
        @ruby_object = @ssh_result.stdout.strip
      end

      if @ssh_result.is_a?(Net::SSH::Simple::Error) && @ruby_object.nil?
        @ruby_object = @ssh_result.wrapped
        @ssh_result.backtrace.each(&method(:puts))
        @ssh_result = @ssh_result.result
      end
    end

    # @return [Boolean] Tells if the result was an exception.  Exceptions are
    #   not representative of failed commands--they are, rather, most likely
    #   due to a problem with making the SSH connection.
    def exception?
      @ruby_object.kind_of?(Exception)
    end

    def failed?
      !@exit_status.zero?
    end

    def no_change?
      @exit_status == :no_change
    end

    def updated?
      @exit_status == :updated
    end

    # @return [Hash] All attributes as a Hash.
    def to_hash
      instance_variables.inject({}) do |result, ivar|
        key = ivar.to_s.delete('@').to_sym
        result[key] = instance_variable_get(ivar)
        result
      end
    end

    # @return [String] All attributes as JSON.
    def to_json
      self.to_hash.to_json
    end

    # @return [String] All attributes as YAML.
    def to_yaml
      self.to_hash.to_yaml
    end
  end
end
