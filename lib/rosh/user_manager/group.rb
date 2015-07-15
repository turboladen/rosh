require_relative '../changeable'
require_relative '../observable'
require_relative 'base'

class Rosh
  class UserManager
    class GroupNotFound < RuntimeError; end

    class Group
      include Rosh::Changeable
      include Rosh::Observable
      include Base

      attr_reader :name

      def initialize(group_name, host_name)
        @name = group_name
        @host_name = host_name
      end

      def members
        adapter.members
      end

      def password
        adapter.passwd
      end

      private

      def adapter
        return @adapter if @adapter

        type = if current_host.local?
                 :local_group
               else
                 case current_host.operating_system
                 when :darwin
                   :open_directory_group
                 else
                   :unix_group
                 end
        end

        @adapter = UserManager::ObjectAdapter.new(@name, type, @host_name)
      end
    end
  end
end
