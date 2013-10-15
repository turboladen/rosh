require_relative '../changeable'
require_relative '../observable'


class Rosh
  class Users
    class User
      include Rosh::Changeable
      include Rosh::Observable

      # @todo Also accept UIDs.
      def initialize(user_name, type, host_name)
        @host_name = host_name
        @user_name = user_name
        @type = type
      end

      def group_id
        adapter.gid
      end
      alias_method :gid, :group_id

      def home_directory
        adapter.home_directory
      end

      def info
        adapter.info
      end

      def reload!
        adapter.reload!
      end

      def real_name
        adapter.real_name
      end

      def shell
        adapter.shell
      end

      def user_id
        adapter.uid
      end
      alias_method :uid, :user_id

      def user_id=(new_uid)
        current_uid = self.user_id
        new_uid = new_uid.to_i

        change_if(current_uid != new_uid) do
          notify_about(self, :user_id, from: current_uid, to: new_uid) do
            adapter.uid = new_uid
          end
        end
      end

      private

      def adapter
        return @adapter if @adapter

        @adapter = case @type
        when :open_directory
          require_relative 'object_adapters/open_directory'
          Users::ObjectAdapters::OpenDirectory
        end

        @adapter.user_name = @user_name
        @adapter.host_name = @host_name

        @adapter
      end
    end
  end
end
