require_relative '../changeable'
require_relative '../observable'


class Rosh
  class Users
    class UserNotFound < RuntimeError; end

    class User
      include Rosh::Changeable
      include Rosh::Observable

      attr_reader :user_name

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

      # Takes a crypted (aka +crypt(3)+) password.
      #
      # On change: This will compare the existing encrypted password with the one
      # given to determine if change should occur.  The new password needs to
      # use the same style of password-ing as the host that you're working on
      # uses.  Thus, if your Unix host uses SHA-512 encryption for passwords,
      # the param given here should look something like:
      #
      #   $6$Mhlu.ZNL$BV9o4Xk8bJfwPypGA0H3gLVdAlUz/g8i3oNm2uoSFp8e/YN3GVp4ZaaU3/ND7loGJX2iYWQizcfDV9KPCCONe0
      #
      # Notification params: +:from+ will be the
      #   * attribute: +:password+
      #   * +:from+: The full shadow'ed passwd string, including id, salt, and
      #     the encrypted string.
      #   * +:to+: The +new_password+ parameter given.
      #
      # @param [String] new_password
      def password=(new_password)
        current_hash = self.password

        change_if(current_hash != new_password) do
          notify_about(self, :password, from: current_hash, to: new_password) do
            adapter.update_attribute(:passwd, new_password)
          end
        end
      end

      # Takes a plain-text password and sets the user's password as such.  Don't
      # use this in scripts, of course, unless you're ok with letting others see
      # the password for this user.
      #
      # On change: This will always try changing the password since there's no
      # way to determine what the old password's plain text was.
      #
      # Notification notes: Will always use +********+ as the text for the old
      # password, and will notify with the new password in plain text.  Again,
      # be sure that objects that get notified are not storing this info unless,
      # of course, you're ok with someone seeing what the password is for this
      # user.
      #
      # @param [String] new_password
      def password_in_plain_text=(new_password)
        change_if(true) do
          notify_about(self, :password, from: '********', to: new_password) do
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
            require_relative 'object_adapters/unix_user'
            Users::ObjectAdapters::UnixUser
          when :darwin
            require_relative 'object_adapters/open_directory_user'
            Users::ObjectAdapters::OpenDirectoryUser
          end
        end

        @adapter.user_name = @user_name
        @adapter.host_name = @host_name

        @adapter
      end
    end
  end
end
