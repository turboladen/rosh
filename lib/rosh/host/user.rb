require 'plist'


class Rosh
  class Host
    class User
      attr_reader :name
      attr_reader :user_id
      attr_reader :group_id

      def initialize(type, name, shell)
        @type = type
        @name = name
        @shell = shell
      end

      def info
        adapter.info
      end

      private

      def adapter
        @adapter ||= create_adapter(@type, @name, @shell)
      end

      def create_adapter(type, name, shell)
        require_relative "user_types/#{type}"

        user_klass = Rosh::Host::UserTypes.const_get(type.to_s.capitalize.to_sym)

        user_klass.new(name, shell)
      end
    end
  end
end
