require 'plist'
require_relative 'group'


class Rosh
  class Host
    class GroupManager
      def initialize(type, host_name)
        @host_name = host_name

        load_strategy(type)
      end

      def [](group_name)
        create_group(group_name)
      end

      def list
        warn 'Not defined!  Define in group manager...'
      end

      private

      def load_strategy(type)
        require_relative "group_managers/#{type}"

        gm_klass =
          Rosh::Host::GroupManagers.const_get(type.to_s.classify)

        extend gm_klass
      end
    end
  end
end
