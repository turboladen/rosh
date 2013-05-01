require_relative '../package_types/rpm'


class Rosh
  class Host
    module PackageManagers
      module Yum

        # Lists all installed Rpm packages.
        #
        # @return [Array<Rosh::Host::PackageTypes::Rpm>]
        def installed_packages
          output = @shell.exec 'yum list'

          output.each_line.map do |line|
            /^(?<name>\S+)\.(?<arch>\S+)\s+(?<version>\S+)\s+(?<status>\S*)/ =~ line
            puts "name: #{name}"
            next unless name

            create(name, architecture: arch, version: version, status: status)
          end
        end

        def update_index
          @shell.exec 'yum update -y'

          @shell.last_exit_status.zero?
        end

        def upgrade(sudo: false)
          cmd = 'yum upgrade -y'
          cmd.insert(0, 'sudo ') if sudo

          @shell.exec(cmd)

          @shell.last_exit_status.zero?
        end

        private

        def create(name, **options)
          Rosh::Host::PackageTypes::Rpm.new(name, @shell, **options)
        end
      end
    end
  end
end
