require_relative '../string_refinements'


class Rosh
  class Host
    class UserManager
      def initialize(type, host_name)
        @host_name = host_name
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
        @adapter ||= create_adapter(@type, @host_name)
      end

      def create_adapter(type, host_name)
        require_relative "user_managers/#{type}"

        um_klass =
          Rosh::Host::UserManagers.const_get(type.to_s.classify)

        um_klass.new(host_name)
      end
    end
  end
end
