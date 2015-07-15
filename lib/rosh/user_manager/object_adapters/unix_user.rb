require 'time'
require 'digest/md5'
require_relative '../../errors'

class Rosh
  class UserManager
    module ObjectAdapters
      module UnixUser
        def add_to_group(group)
          current_shell.exec_internal "usermod --append --groups #{group} #{@name}"

          current_shell.last_exit_status.zero?
        end

        def age
          Time.now - change
        end

        def change
          result = current_shell.exec_internal "chage --list #{@name} | grep 'Last password change'"
          date = result.split(': ').last

          Time.parse(date)
        end

        # @todo Figure out what this should return.
        def comment
          warn 'Not implemented.'
        end

        def create
          cmd = "useradd #{@name}"
          result = current_shell.exec_internal(cmd)

          if current_shell.last_exit_status.zero?
            true
          elsif current_shell.last_exit_status == 127 ||
                result.match(/command not found/)
            fail Rosh::Shell::CommandNotFound, cmd
          end
        end

        def delete
          current_shell.exec_internal "userdel #{@name}"

          current_shell.last_exit_status.zero?
        end

        def dir
          getent_passwd[:dir]
        end

        def exists?
          current_shell.exec_internal "id #{@name}"

          current_shell.last_exit_status.zero?
        end

        def expire
          result = current_shell.exec_internal "chage --list #{@name} | grep 'Account expires'"
          date = result.split(': ').last

          date.strip == 'never' ? nil : Time.parse(date)
        end

        def gecos
          getent_passwd[:gecos]
        end

        def gid
          result = current_shell.exec_internal "id --group #{@name}"

          result.to_i
        end

        def info
          getent_passwd
        end

        def name
          result = current_shell.exec_internal "id --user --name #{@name}"

          result.strip
        end

        def passwd
          getent_shadow[:passwd]
        end

        def real_name
          gecos.split(',').first
        end

        def shell
          getent_passwd[:shell]
        end

        def uid
          result = current_shell.exec_internal "id --user #{@name}"

          result.to_i
        end

        private

        def getent_passwd
          cmd = "getent passwd #{@name}"
          result = current_shell.exec_internal cmd

          if result.match /Permission denied/
            fail Rosh::PermissionDenied, "Command: #{cmd}"
          end

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
          result = current_shell.exec_internal "getent shadow #{@name}"
          result_split = result.split(':')

          {
            name: result_split[0],
            passwd: result_split[1],
            last_changed: Time.at(result_split[2].to_i * 86_400),
            days_before_can_change: result_split[3].to_i,
            days_before_must_change: result_split[4].to_i,
            days_before_change_warning: result_split[5].to_i,
            days_before_disabled: result_split[6].strip.to_i,
            days_since_disabled: result_split[7].empty? ? nil : Time.at(result_split[7].to_i * 86_400),
            encrypted_with: password_encryption_type(result_split[1]),
            salt: password_salt(result_split[1]),
            encrypted_passwd: password_encrypted(result_split[1])
          }
        end

        def dir=(new_dir)
          current_shell.exec_internal %(usermod --home "#{new_dir}" --move-home #{@name})

          current_shell.last_exit_status.zero?
        end

        def gid=(new_gid)
          current_shell.exec_internal %(usermod --gid #{new_gid} #{@name})

          current_shell.last_exit_status.zero?
        end

        def name=(new_name)
          current_shell.exec_internal "usermod --login #{new_name} #{@name}"

          current_shell.last_exit_status.zero?
        end

        def passwd=(new_password)
          cmd = %(echo "#{@name}:#{new_password}" | chpasswd)
          current_shell.exec_internal cmd

          current_shell.last_exit_status.zero?
        end

        def real_name=(new_name)
          current_shell.exec_internal %(chfn --full-name "#{new_name}" #{@name})

          current_shell.last_exit_status.zero?
        end

        def shell=(new_shell)
          current_shell.exec_internal %(usermod --shell "#{new_shell}" #{@name})

          current_shell.last_exit_status.zero?
        end

        def uid=(new_uid)
          current_shell.exec_internal %(usermod --uid #{new_uid} #{@name})

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
