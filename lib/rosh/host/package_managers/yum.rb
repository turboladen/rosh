require_relative '../package_types/yum'


class Rosh
  class Host
    module PackageManagers
      module Yum
        def update(sudo: false)
          cmd = 'yum update -y'
          cmd.insert(0, 'sudo ') if sudo

          @shell.exec(cmd)

          @shell.last_exit_status.zero?
        end

        def upgrade(sudo: false)
          cmd = 'yum upgrade -y'
          cmd.insert(0, 'sudo ') if sudo

          @shell.exec(cmd)

          @shell.last_exit_status.zero?
        end

        def list(sudo: false)
          cmd = 'yum list'
          cmd.insert(0, 'sudo ') if sudo

          @shell.exec(cmd)
        end

        private

        def create(name)
          Rosh::Host::PackageTypes::Yum.new(@shell, name)
        end
      end
    end
  end
end
