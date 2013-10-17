require 'etc'
require_relative '../user'


class Rosh
  class Users
    module ManagerAdapters
      class LocalManager
        include Base

        class << self
          def list
            users = []

            Etc.passwd do |struct|
              users << Rosh::Users::User.new(struct.name, @host_name)
            end

            users
          end

          def user?
            begin
              info_by_name
            rescue ArgumentError
              return false
            end

            true
          end
        end
      end
    end
  end
end
