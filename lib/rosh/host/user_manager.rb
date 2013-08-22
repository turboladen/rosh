require_relative '../string_refinements'


class Rosh
  class Host
    class UserManager
      def initialize(type, host_label)
        @host_label = host_label
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
        @adapter ||= create_adapter(@type, @host_label)
      end

      def create_adapter(type, host_label)
        require_relative "user_managers/#{type}"

        um_klass =
          Rosh::Host::UserManagers.const_get(type.to_s.classify)

        um_klass.new(host_label)
      end
    end
  end
end
