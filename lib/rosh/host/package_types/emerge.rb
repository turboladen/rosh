class Rosh
  class Host
    module PackageTypes
      class Emerge
        attr_reader :name

        def initialize(shell, name)
          @shell = shell
          @name = name
        end

        def install(sudo: false)
          cmd = "emerge #{name}"
          cmd.insert(0, 'sudo ') if sudo
          @shell.exec(cmd)

          @shell.last_exit_status.zero?
        end

        def remove(sudo: false)
          cmd = "emerge --unmerge #{name}"
          cmd.insert(0, 'sudo ') if sudo
          @shell.exec(cmd)

          @shell.last_exit_status.zero?
        end
      end
    end
  end
end
