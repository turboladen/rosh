require 'open-uri'
require 'fileutils'
require 'sys/proctable'
require_relative 'host/file_system'

Dir[File.dirname(__FILE__) + '/builtin_commands/*.rb'].each(&method(:require))


class Rosh
  module BuiltinCommands

    Rosh::BuiltinCommands.constants.each do |action_class|
      define_method(action_class.to_s.downcase.to_sym) do |*args, **options, &block|
        klass = Rosh::BuiltinCommands.const_get(action_class)

        if options.empty? && args.empty?
          klass.new(&block)
        elsif options.empty?
          klass.new(*args, &block)
        elsif args.empty?
          klass.new(*args, &block)
        else
          klass.new(*args, **options, &block)
        end
      end
    end

    def fs
      @fs ||= Host::FileSystem.new
    end

    def ruby(code)
      status = 0

      result = begin
        code.gsub!(/puts/, '$stdout.puts')
        get_binding.eval(code)
      rescue => ex
        status = 1
        ex
      end

      [status, result]
    end
  end
end
