class Rosh
  class UserManager
    module Base
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

      def password
        adapter.passwd
      end
    end
  end
end
