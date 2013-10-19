require 'etc'
require_relative 'base'
require_relative '../user'
require_relative '../group'


class Rosh
  class Users
    module ManagerAdapters
      class Local
        include Base

        class << self
          def groups
            groups = []

            Etc.group do |struct|
              groups << Rosh::Users::Group.new(struct.name, @host_name)
            end

            groups
          end

          def users
            users = []

            Etc.passwd do |struct|
              users << Rosh::Users::User.new(struct.name, @host_name)
            end

            users
          end

          def user?(name)
            begin
              ::Etc.getpwnam(name)
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
