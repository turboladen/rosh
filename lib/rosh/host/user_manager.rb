require_relative '../string_refinements'


class Rosh
  class Host
    class UserManager
      def initialize(type, host_name)
        @host_name = host_name

        load_strategy(type)
      end

      def [](user_name)
        create_user(user_name)
      end

      def list
        warn 'Not defined!  Define in user manager...'
      end

      private

      def load_strategy(type)
        require_relative "user_managers/#{type}"

        um_klass =
          Rosh::Host::UserManagers.const_get(type.to_s.classify)

        extend um_klass
      end
    end
  end
end
