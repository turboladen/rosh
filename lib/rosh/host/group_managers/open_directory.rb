class Rosh
  class Host
    module GroupManagers
      module OpenDirectory
        def list
          result = current_shell.exec 'dscacheutil -q group'
          group_texts = result.split("\r\n\r\n")

          group_texts.map do |group_text|
            group = group_text.each_line.inject({}) do |result, line|
              line.strip!
              next if line.empty?
              %r[(?<key>\S+):\s+(?<value>.+)$] =~ line.strip

              value = value.split if key == 'users'
              result[key.to_sym] = value

              result
            end

            group.delete(:password)
            name = group.delete(:name)
            create_group(name, group)
          end
        end

        private

        def create_group(name, **options)
          Rosh::Host::Group.new(:open_directory, name, @host_name, **options)
        end
      end
    end
  end
end
