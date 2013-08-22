require_relative 'string_refinements'


class Rosh
  class Host
    class UserManager
      def initialize(type, shell)
        @shell = shell
        @type = type
      end

      def [](user_name)
        adapter.create_user(user_name)
      end

      def list
        adapter.list
      end

      private

      def adapter
        @adapter ||= create_adapter(@type, @shell)
      end

      def create_adapter(type, shell)
        require_relative "user_managers/#{type}"

        um_klass =
          Rosh::Host::UserManagers.const_get(type.to_s.classify)

        um_klass.new(shell)
      end
    end
  end
end
