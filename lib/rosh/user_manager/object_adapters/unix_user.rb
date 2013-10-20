require 'time'
require 'digest/md5'
require_relative 'base_user'


class Rosh
  class UserManager
    module ObjectAdapters
      class UnixUser
        include BaseUser

        class << self
          def add_to_group(group)
            current_shell.exec "usermod --append --groups #{group} #{@user_name}"

            current_shell.last_exit_status.zero?
          end

          def age
            Time.now - change
          end

          def change
            result = current_shell.exec "chage --list #{@user_name} | grep 'Last password change'"
            date = result.split(': ').last

            Time.parse(date)
          end

          # @todo Figure out what this should return.
          def comment

          end

          def create
            current_shell.exec "useradd #{@user_name}"

            current_shell.last_exit_status.zero?
          end

          def delete
            current_shell.exec "userdel #{@user_name}"

            current_shell.last_exit_status.zero?
          end

          def dir
            getent_passwd[:dir]
          end

          def exists?
            current_shell.exec "id #{@user_name}"

            current_shell.last_exit_status.zero?
          end

          def expire
            result = current_shell.exec "chage --list #{@user_name} | grep 'Account expires'"
            date = result.split(': ').last

            date.strip == 'never' ? nil : Time.parse(date)
          end

          def gecos
            getent_passwd[:gecos]
          end

          def gid
            result = current_shell.exec "id --group #{@user_name}"

            result.to_i
          end

          def info
            getent_passwd
          end

          def name
            result = current_shell.exec "id --user --name #{@user_name}"

            result.strip
          end

          def passwd
            getent_shadow[:passwd]
          end

          def real_name
            self.gecos.split(',').first
          end

          def shell
            getent_passwd[:shell]
          end

          def uid
            result = current_shell.exec "id --user #{@user_name}"

            result.to_i
          end

          private

          def getent_passwd
            result = current_shell.exec "getent passwd #{@user_name}"
            result_split = result.split(':')

            {
              name: result_split[0],
              passwd: result_split[1],
              uid: result_split[2].to_i,
              gid: result_split[3].to_i,
              gecos: result_split[4],
              dir: result_split[5],
              shell: result_split[6].strip
            }
          end

          def getent_shadow
            result = current_shell.exec "getent shadow #{@user_name}"
            result_split = result.split(':')

            {
              name: result_split[0],
              passwd: result_split[1],
              last_changed: Time.at(result_split[2].to_i * 86400),
              days_before_can_change: result_split[3].to_i,
              days_before_must_change: result_split[4].to_i,
              days_before_change_warning: result_split[5].to_i,
              days_before_disabled: result_split[6].strip.to_i,
              days_since_disabled: result_split[7].empty? ? nil :Time.at(result_split[7].to_i * 86400),
              encrypted_with: password_encryption_type(result_split[1]),
              salt: password_salt(result_split[1]),
              encrypted_passwd: password_encrypted(result_split[1])
            }
          end

          def dir=(new_dir)
            current_shell.exec %[usermod --home "#{new_dir}" --move-home #{@user_name}]

            current_shell.last_exit_status.zero?
          end

          def gid=(new_gid)
            current_shell.exec %[usermod --gid #{new_gid} #{@user_name}]

            current_shell.last_exit_status.zero?
          end

          def name=(new_name)
            current_shell.exec "usermod --login #{new_name} #{@user_name}"

            current_shell.last_exit_status.zero?
          end

          def passwd=(new_password)
            cmd = %[echo "#{@user_name}:#{new_password}" | chpasswd]
            current_shell.exec cmd

            current_shell.last_exit_status.zero?
          end

          def real_name=(new_name)
            current_shell.exec %[chfn --full-name "#{new_name}" #{@user_name}]

            current_shell.last_exit_status.zero?
          end

          def shell=(new_shell)
            current_shell.exec %[usermod --shell "#{new_shell}" #{@user_name}]

            current_shell.last_exit_status.zero?
          end

          def uid=(new_uid)
            current_shell.exec %[usermod --uid #{new_uid} #{@user_name}]

            current_shell.last_exit_status.zero?
          end

          def password_encryption_type(pass)
            case pass[0..1]
            when '$1'
              :md5
            when '$2a'
              :blowfish
            when '$5'
              :sha256
            when '$6'
              :sha512
            end
          end

          def password_salt(pass)
            pass.split('$')[2]
          end

          def password_encrypted(pass)
            pass.split('$')[3]
          end
        end
      end
    end
  end
end
