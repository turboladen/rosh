class Rosh
  class UserManager
    module ObjectAdapters
      module BaseUser
        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          def user_name=(user_name)
            @user_name = user_name
          end

          def host_name=(host_name)
            @host_name = host_name
          end

          def update_attribute(key, value)
            self.send("#{key}=", value)
          end
        end
      end
    end
  end
end
