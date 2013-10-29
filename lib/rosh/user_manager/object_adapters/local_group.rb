require 'etc'
require_relative '../user'


class Rosh
  class UserManager
    module ObjectAdapters
      module LocalGroup
        def self.extended(base)
          @host_name = base.instance_variable_get(:@host_name)

          type = case current_host.operating_system
          when :darwin
            :open_directory_group
          else
            :unix_group
          end

          require_relative "#{type}"
          klass =
            Rosh::UserManager::ObjectAdapters.const_get(type.to_s.classify)
          base.extend klass
        end

        def create
          adapter_adapter.create
        end

        def delete
          adapter_adapter.delete
        end

        def exists?
          begin
            info_by_name
          rescue
            return false
          end
        end

        def gid
          info_by_name.gid
        end

        def members
          info_by_name.mem.map do |user_name|
            UserManager::User.new(user_name, @host_name)
          end
        end

        def name
          info_by_name.name
        end

        def passwd
          info_by_name.passwd
        end

        private

        def info_by_name
          ::Etc.getgrnam(@group_name)
        end

        def adapter_adapter
          return @adapter if @adapter

          type = case current_host.operating_system
          when :darwin
            :open_directory_group
          else
            :unix_group
          end

          @adapter = Rosh::UserManager::ObjectAdapter.new(@name, type, @host_name)
        end
      end
    end
  end
end
