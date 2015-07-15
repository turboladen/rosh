class Rosh
  class UserManager
    class ObjectAdapter
      def initialize(name, type, host_name)
        @name = name
        @host_name = host_name

        load_adapter(type)
      end

      def update_attribute(key, value)
        self.send("#{key}=", value)
      end

      private

      def load_adapter(type)
        require_relative "object_adapters/#{type}"
        klass =
          Rosh::UserManager::ObjectAdapters.const_get(type.to_s.classify)
        self.extend klass
      end
    end
  end
end
