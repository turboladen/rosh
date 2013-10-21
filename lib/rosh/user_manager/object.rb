require_relative '../changeable'
require_relative '../observable'


class Rosh
  class UserManager
    class Object
      include Rosh::Changeable
      include Rosh::Observable

      def initialize(user_name, host_name)
        @user_name = user_name
        @host_name = host_name
      end
    end
  end
end
