require_relative 'base'
require_relative '../user'
require_relative '../group'


class Rosh
  class UserManager
    module ManagerAdapters
      class OpenDirectory
        include Base

        class << self
          def groups
            result = current_shell.exec 'dscacheutil -q group'
            group_texts = result.split("\r\n\r\n")

            group_texts.map do |group_text|
              group = group_text.each_line.inject({}) do |result, line|
                line.strip!
                next if line.empty?
                %r[(?<key>\S+):\s+(?<value>.+)$] =~ line.strip

                value = value.split if key == 'users'
                result[key.to_sym] = value

                result
              end

              group.delete(:password)
              name = group.delete(:name)
              UserManager::Group.new(name, @host_name)
            end
          end

          def group?(name)
            cmd = "dscl . -read /Groups/#{name}"
            current_shell.exec cmd

            current_shell.last_exit_status.zero?
          end

          def users
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
              UserManager::User.new(name, @host_name)
            end
          end

          def user?(name)
            cmd = "dscl . -read /Users/#{name}"
            current_shell.exec cmd

            current_shell.last_exit_status.zero?
          end
        end
      end
    end
  end
end
