require 'plist'


class Rosh
  class Host
    class Group
      attr_reader :name

      def initialize(type, name, host_name, gid: nil, users: [])
        @name = name
        @host_name = host_name
        @group_id = gid.to_i if gid
        @users = users

        load_strategy(type)
      end

      def info
        warn 'Not defined!  Define in group type...'
      end

      private

      def load_strategy(type)
        require_relative "group_types/#{type}"

        group_klass = Rosh::Host::GroupTypes.const_get(type.to_s.classify)

        self.extend group_klass
      end
    end
  end
end
