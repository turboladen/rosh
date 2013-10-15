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
        info['dsAttrTypeStandard:PrimaryGroupID'].first.to_i
      end
      alias_method :gid, :group_id

      def home_directory
        info['dsAttrTypeStandard:NFSHomeDirectory'].first
      end

      def info
        @info ||= adapter.info
      end

      def real_name
        info['dsAttrTypeStandard:RealName'].first
      end

      def shell
        info['dsAttrTypeStandard:UserShell'].first
      end

      def user_id
        info['dsAttrTypeStandard:UniqueID'].first.to_i
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
