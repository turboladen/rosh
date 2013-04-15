require_relative 'base'
require_relative '../package_types/brew'


class Rosh
  class Host
    module PackageManagers
      class Brew < Base
        def initialize(shell)
          super(shell)
        end

        def list
          result = @shell.exec 'brew list'

          result.split(/\s+/).map do |pkg|
            create(pkg)
          end
        end

        def update
          @shell.exec '/usr/bin/env brew update'

          @shell.history.last[:exit_status].zero?
        end

        # @param [String,Regexp] text
        # @return [Array]
        def search(text=nil)
          text = "/#{text.source}/" if text.is_a? Regexp

          result = @shell.exec("brew search #{text}")

          # For some reason, doing this causes a memory leak and Ruby blows up.
          #packages = result.split(/\s+/).map do |pkg|
          #  puts "package #{pkg}"
          #  create(pkg)
          #end

          result.split(/\s+/)
        end

        private

        def create(name)
          Rosh::Host::PackageTypes::Brew.new(@shell, name)
        end
      end
    end
  end
end
