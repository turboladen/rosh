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

      def create
        change_if(!exists?) do
          notify_about(self, :exists?, from: false, to: true) do
            adapter.create
          end
        end
      end

      def delete
        change_if(exists?) do
          notify_about(self, :exists?, from: true, to: false) do
            adapter.delete
          end
        end
      end

      def exists?
        adapter.exists?
      end

      def group_id
        adapter.gid
      end
      alias_method :gid, :group_id

      def group_id=(new_gid)
        current_gid = self.group_id

        change_if(current_gid != new_gid) do
          notify_about(self, :group_id, from: current_gid, to: new_gid) do
            adapter.update_attribute(:gid, new_gid)
          end
        end
      end

      # @todo Should this return a Rosh::FileSystem::Directory?
      def home_directory
        adapter.dir
      end
      alias_method :dir, :home_directory

      def home_directory=(new_home)
        current_home = self.home_directory

        change_if(current_home != new_home) do
          notify_about(self, :home_directory, from: current_home, to: new_home) do
            adapter.update_attribute(:dir, new_home)
          end
        end
      end

      def info
        adapter.info
      end

      def password
        adapter.passwd
      end

      # @todo Fix updating
      def password=(new_password)
        change_if(true) do
          notify_about(self, :password, from: 'xxx', to: 'xxx') do
            adapter.update_attribute(:passwd, new_password)
          end
        end
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
        adapter.real_name
      end

      def real_name=(new_name)
        current_name = self.real_name

        change_if(current_name != new_name) do
          notify_about(self, :shell, from: current_name, to: new_name) do
            adapter.update_attribute(:real_name, new_name)
          end
        end
      end

      def shell
        adapter.shell
      end

      def shell=(new_shell)
        current_shell = self.shell

        change_if(current_shell != new_shell) do
          notify_about(self, :shell, from: current_shell, to: new_shell) do
            adapter.update_attribute(:shell, new_shell)
          end
        end
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
            adapter.update_attribute(:uid, new_uid)
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
