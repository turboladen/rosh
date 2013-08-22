require 'plist'
require_relative '../user_types/open_directory'


class Rosh
  class Host
    module UserManagers
      class OpenDirectory
        def initialize(shell)
          @shell = shell
        end

        def list
          result = @shell.exec 'dscacheutil -q user'
          user_texts = result.split("\r\n\r\n")

          user_texts.map do |user_text|
            user = user_text.each_line.inject({}) do |result, line|
              line.strip!
              next if line.empty?
              %r[(?<key>\S+):\s+(?<value>.+)$] =~ line.strip
              result[key.to_sym] = value

              result
            end

            create_user(user[:name])
          end
        end

        def create_user(name)
          Rosh::Host::UserTypes::OpenDirectory.new(name, @shell)
        end
      end
    end
  end
end
