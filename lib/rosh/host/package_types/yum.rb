class Rosh
  class Host
    module PackageTypes
      class Yum
        attr_reader :name

        def initialize(shell, name)
          @shell = shell
          @name = name
        end

        def info(sudo: false)
          cmd = "yum info #{@name}"
          cmd.insert(0, 'sudo ') if sudo

          @shell.exec(cmd)
        end

        def install(sudo: false)
          cmd = "yum install #{@name}"
          cmd.insert(0, 'sudo ') if sudo
          @shell.exec(cmd)

          @shell.last_exit_status.zero?
        end

        def remove(sudo: false)
          cmd = "yum remove #{@name}"
          cmd.insert(0, 'sudo ') if sudo
          @shell.exec(cmd)

          @shell.last_exit_status.zero?
        end
      end
    end
  end
end
