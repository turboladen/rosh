require_relative 'base'
require_relative '../package'


class Rosh
  class PackageManager
    module ManagerAdapters

      # It's not quite safe to call this the 'Apt' adapter, as some commands
      # make use of +dpkg+...
      class Apt
        DEFAULT_BIN_PATH = '/usr/bin'
        include Base

        class << self

          def installed_packages
            result = current_shell.exec 'dpkg --list'

            result.split("\n").map do |pkg|
              if pkg.match(/^[A-za-z]{1,3}\s+/)
                %r[(?<status>[\w]{1,3})\s+(?<name>\S+)\s+(?<version>\S+)\s+(?<description>[^\n]+)] =~
                  pkg

                Rosh::PackageManager::Package.new(name, @host_name)
              end
            end.compact
          end

          def update_definitions
            output = current_shell.exec 'DEBIAN_FRONTEND=noninteractive apt-get update -y'

            extract_updated_definitions(output)
          end

          def upgrade_packages
            current_shell.exec 'DEBIAN_FRONTEND=noninteractive apt-get upgrade -y'

            current_shell.last_exit_status.zero?
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
        end
      end
    end
  end
end
