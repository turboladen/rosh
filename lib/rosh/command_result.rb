require 'log_switch'


class Rosh
  class CommandResult
    extend LogSwitch
    include LogSwitch::Mixin

    attr_reader :exit_status
    attr_reader :ruby_object
    attr_reader :stdout
    attr_reader :stderr

    def initialize(ruby_object, exit_status, stdout=nil, stderr=nil)
      @ruby_object = ruby_object
      @exit_status = exit_status
      @stdout = stdout
      @stderr = stderr

      if @stdout && !@stdout.empty? && @ruby_object.nil?
        @ruby_object = @stdout.strip
      end

=begin
      if @ssh_result.is_a?(Net::SSH::Simple::Error) && @ruby_object.nil?
        @ruby_object = @ssh_result.wrapped
        @ssh_result.backtrace.each(&method(:puts))
        @ssh_result = @ssh_result.result
      end
=end
      msg = "New result: ruby_object=#{@ruby_object}; "
      msg << "exit_status: #{@exit_status}; "
      msg << "stdout=#{@stdout}; stderr=#{@stderr}"
      log msg
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
  end
end

Rosh::CommandResult.log_class_name = true
