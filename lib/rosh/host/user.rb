require 'plist'
require_relative '../string_refinements'


class Rosh
  class Host
    class User
      attr_reader :name
      attr_reader :user_id
      attr_reader :group_id

      def initialize(type, name, host_label)
        @type = type
        @name = name
        @host_label = host_label
      end

      def info
        adapter.info
      end

      private

      def adapter
        @adapter ||= create_adapter(@type, @name, @host_label)
      end

      def create_adapter(type, name, host_label)
        require_relative "user_types/#{type}"

        user_klass = Rosh::Host::UserTypes.const_get(type.to_s.classify)

        user_klass.new(name, host_label)
      end
    end
  end
end
