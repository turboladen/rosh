require_relative '../changeable'
require_relative '../observable'


class Rosh
  class Users
    class User
      include Rosh::Changeable
      include Rosh::Observable

      # @todo Also accept UIDs.
      def initialize(name, type, host_name)
        @host_name = host_name
        @name = name
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

      private

      def adapter
        return @adapter if @adapter

        @adapter = case @type
        when :open_directory
          require_relative 'object_adapters/open_directory'
          Users::ObjectAdapters::OpenDirectory
        end

        @adapter.name = @name
        @adapter.host_name = @host_name

        @adapter
      end
    end
  end
end
