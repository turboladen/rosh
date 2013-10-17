require_relative '../changeable'
require_relative '../observable'


class Rosh
  class Users
    class User
      include Rosh::Changeable
      include Rosh::Observable

      # @todo Also accept UIDs.
      def initialize(user_name, host_name)
        @host_name = host_name
        @user_name = user_name
      end

      def group_id
        adapter.gid
      end
      alias_method :gid, :group_id

      def home_directory
        adapter.dir
      end
      alias_method :dir, :home_directory

      def info
        adapter.info
      end

      def password
        adapter.passwd
      end

      def password_age
        adapter.age
      end

      def password_change_time
        adapter.change
      end

      def password_expiration_time
        adapter.expire
      end

      def quota
        adapter.quota
      end

      def real_name
        #adapter.real_name
        adapter.gecos.split(',').first
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

        @adapter = if current_host.local?
          require_relative 'object_adapters/local_user'
          Users::ObjectAdapters::LocalUser
        else
          case current_host.operating_system
          when :linux
            require_relative 'object_adapters/unix'
            Users::ObjectAdapters::Unix
          when :darwin
            require_relative 'object_adapters/open_directory'
            Users::ObjectAdapters::OpenDirectory
          end
        end

        @adapter.user_name = @user_name
        @adapter.host_name = @host_name

        @adapter
      end
    end
  end
end
