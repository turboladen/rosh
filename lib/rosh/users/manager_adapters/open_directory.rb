require_relative 'base'
require_relative '../user'


class Rosh
  class Users
    module ManagerAdapters
      class OpenDirectory
        include Base

        class << self
          def list
            result = current_shell.exec 'dscacheutil -q user'
            user_texts = result.split("\r\n\r\n")

            user_texts.map do |user_text|
              user = user_text.each_line.inject({}) do |result, line|
                line.strip!
                next if line.empty?
                %r[(?<key>\S+):\s+(?<value>.+)$] =~ line.strip

                result[key.to_sym] = value unless key == 'password'

                result
              end

              name = user.delete(:name)
              #Users::User.new(name, :open_directory, @host_name, user)
              Users::User.new(name, :open_directory, @host_name)
            end
          end
        end
      end
    end
  end
end
