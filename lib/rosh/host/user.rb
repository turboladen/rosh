require 'plist'
require_relative '../string_refinements'


class Rosh
  class Host
    class User
      attr_reader :name

      def initialize(type, name, host_label, **options)
        @type = type
        @name = name
        @host_label = host_label
        @options = options
      end

      def info
        adapter.info
      end

      def user_id
        adapter.user_id
      end

      def group_id
        adapter.group_id
      end

      def home_directory
        adapter.home_directory
      end

      def shell
        adapter.shell
      end

      private

      def adapter
        @adapter ||= create_adapter(@type, @name, @host_label, **@options)
      end

      def create_adapter(type, name, host_label, **options)
        require_relative "user_types/#{type}"

        user_klass = Rosh::Host::UserTypes.const_get(type.to_s.classify)

        user_klass.new(name, host_label, **options)
      end
    end
  end
end
