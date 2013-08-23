require 'plist'
require_relative '../user_types/open_directory'


class Rosh
  class Host
    module UserManagers
      class OpenDirectory
        def initialize(host_name)
          @host_name = host_name
        end

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
            create_user(name, user)
          end
        end

        def create_user(name, **options)
          Rosh::Host::UserTypes::OpenDirectory.new(name, @host_name, **options)
        end
      end
    end
  end
end
