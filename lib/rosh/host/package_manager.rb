Dir[File.dirname(__FILE__) + '/package_managers/*.rb'].each(&method(:require))


class Rosh
  class Host
    class PackageManager

      def initialize(shell, *manager_types)
        @shell = shell

        manager_types.each do |type|
          self.class.
            send(:prepend, Rosh::Host::PackageManagers.const_get(type.to_s.capitalize.to_sym))
        end
      end

      def [](package_name)
        create(package_name)
      end
    end
  end
end
