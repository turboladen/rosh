class Rosh
  module CommandWrappers
    class Brew
      def initialize
        @base = 'brew'
      end

      def install(package, *args)
        cmd = %[#{@base} install ]
        cmd << args.join(' ') unless args.empty?
        cmd << package

      end

      def remove(package, *args)

      end

      def update

      end

      def upgrade(package=nil)

      end

      def search(package)

      end

      def list

      end
    end
  end
end
