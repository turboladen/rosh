require_relative '../string_refinements'


class Rosh
  class Host
    class User
      attr_reader :name

      def initialize(type, name, host_name, uid: nil, gid: nil, dir: nil, shell: nil,
        gecos: nil
      )
        @name = name
        @host_name = host_name
        @user_id = uid.to_i
        @group_id = gid.to_i
        @home_directory = dir
        @shell = shell
        @description = gecos

        load_strategy(type)
      end

      def info
        warn 'Not defined! Define in user type...'
      end

      def user_id
        warn 'Not defined! Define in user type...'

        @user_id
      end

      def group_id
        warn 'Not defined! Define in user type...'

        @group_id
      end

      def home_directory
        warn 'Not defined! Define in user type...'

        @home_directory
      end

      def shell
        warn 'Not defined! Define in user type...'

        @shell
      end

      def description
        warn 'Not defined! Define in user type...'

        @description
      end
      private

      def load_strategy(type)
        require_relative "user_types/#{type}"

        user_klass = Rosh::Host::UserTypes.const_get(type.to_s.classify)

        self.extend user_klass
      end
    end
  end
end
