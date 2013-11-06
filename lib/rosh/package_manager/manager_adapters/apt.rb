require_relative '../package'


class Rosh
  class PackageManager
    module ManagerAdapters

      # It's not quite safe to call this the 'Apt' adapter, as some commands
      # make use of +dpkg+...
      module Apt
        DEFAULT_BIN_PATH = '/usr/bin'

        def installed_packages
          result = current_shell.exec_internal 'dpkg --list'

          result.split("\n").map do |pkg|
            if pkg.match(/^[A-za-z]{1,3}\s+/)
              %r[(?<status>[\w]{1,3})\s+(?<name>\S+)\s+(?<version>\S+)\s+(?<description>[^\n]+)] =~
                pkg

              Rosh::PackageManager::Package.new(name, @host_name)
            end
          end.compact
        end

        def update_definitions
          output = current_shell.exec_internal 'DEBIAN_FRONTEND=noninteractive apt-get update -y'

          extract_updated_definitions(output)
        end

        def upgrade_packages
          output = current_shell.exec_internal 'DEBIAN_FRONTEND=noninteractive apt-get upgrade -y'

          if output.match /0 upgraded/m
            puts 'Nothing upgraded'
            return []
          end

          extract_upgraded_packages(output)
        end

        private

        # Extracts the list of updated package definitions from the output of
        # a #update_definitions call.
        #
        # @param [String] output from the #update_defintions call.
        # @return [Array<Hash{source: String, distribution: String, components: Array, size: String}]
        # TODO: How to deal with output being an Exception?
        def extract_updated_definitions(output)
          return [] unless output.is_a? String

          updated = []

          output.each_line do |line|
            next unless line.start_with?('Get:')

            %r(Get:\d\s+(?<get_source>\S+)\s(?<distro>\S+)\s(?<components>[^\[]+)\s\[(?<size>[^\]]+)) =~ line

            updated << {
              source: get_source,
              distribution: distro,
              components: components.split(' '),
              size: size
            }
          end

          updated.compact
        end

        # Extracts Deb package names for #upgrade_packages from the command
        # output.
        #
        # @param [String] output Output from the apt-get upgrade command.
        # @return [Array<String>]
        def extract_upgraded_packages(output)
          new_packages = []

          output.each_line do |line|
            next if line.match(/The following packages will be upgraded:/)
            break if line.match(/\d+ upgraded, \d+ newly installed/)

            line.split.each do |pkg|
              puts "pkg #{pkg}"
              new_packages << PackageManager::Package.new(pkg, @host_name)
            end
          end

          new_packages
        end
      end
    end
  end
end
