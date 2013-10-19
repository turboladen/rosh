class Rosh
  class Users
    module ObjectAdapters
      module BaseGroup
        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          def group_name=(group_name)
            @group_name = group_name
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
