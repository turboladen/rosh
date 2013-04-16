require_relative '../package_types/emerge'


class Rosh
  class Host
    module PackageManagers
      module Emerge
        def update_cache(sudo: false)
          cmd = 'emerge --sync'
          cmd.insert(0, 'sudo ') if sudo
          @shell.exec(cmd)

          unless @shell.last_exit_status.zero?
            return false
          end

          cmd = 'emerge portage'
          cmd.insert(0, 'sudo ') if sudo
          @shell.exec(cmd)

          @shell.last_exit_status.zero?
        end

        def update_packages(sudo: false)
          cmd = 'emerge --update world'
          cmd.insert(0, 'sudo ') if sudo
          @shell.exec(cmd)

          @shell.last_exit_status.zero?
        end

        def search(name, sudo: false)
          cmd = "emerge --search #{name}"
          cmd.insert(0, 'sudo ') if sudo
          result = @shell.exec(cmd)

          result.each_line.map do |line|
            %r[\*\s*\S*/(?<name>\S+)] =~ line
            create(name) if name
          end.compact
        end

        private

        def create(name)
          Rosh::Host::PackageTypes::Emerge.new(@shell, name)
        end
      end
    end
  end
end
