require_relative '../package_types/brew'


class Rosh
  class Host
    module PackageManagers
      module Brew

        # Lists all packages that exist in the homebrew cache.
        #
        # @return [Hash{ String => Hash }]
        def cache
          return @cache if @cache && !@cache_is_dirty

          output = @shell.exec 'ls `brew --cache`'
          cached_packages = {}

          output.split.each do |pkg|
            /^(?<name>\w*(-\w*)?)-(?<version>(\d+[^\.]*\.)+)/ =~ pkg
            puts "name: #{name}"
            puts "version: #{version}"

            next unless name
            version.chomp!('.') if version
            cached_packages[name.strip] = { arch: '', version: version.strip }
          end

          @cache = Hash[cached_packages.sort]
        end

        # Lists all installed Brew packages.
        #
        # @return [Array<Rosh::Host::PackageTypes::Brew>]
        def list
          result = @shell.exec 'brew list'

          result.split(/\s+/).map do |pkg|
            create(pkg)
          end
        end

        # Updates homebrew's cache using `brew update`.
        #
        # @return [Boolean] +true+ if exit status was 0; +false+ if not.
        def update_cache
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
