require 'fileutils'
require_relative 'local_base'
require_relative '../../errors'
require_relative '../../shell/private_command_result'


class Rosh
  class FileSystem
    module ObjectAdapters
      module LocalFile
        include LocalBase

        attr_accessor :unwritten_contents

        def create(&block)
          handle_errors_and_return_result do
            f = ::File.open(@path, ::File::CREAT, &block)

            ::File.exists? f
          end
        end

        def read(length=nil, offset=nil)
          handle_errors_and_return_result do
            ::File.read(@path, length, offset)
          end
        end

        def readlines(separator)
          handle_errors_and_return_result do
            [::File.readlines(@path, separator)]
          end
        end

        def copy(destination)
          handle_errors_and_return_result do
            ::FileUtils.cp(@path, destination)

            new_file = current_host.fs[file: destination]
            new_file.save
            new_file
          end
        end

        def save
          handle_errors_and_return_result do
            ok = if @unwritten_contents
              ::File.open(@path, 'w') do |f|
                f.write(@unwritten_contents)
              end

              true
            else
              false
            end

            exit_status = ok ? 0 : 1

            [ok, exit_status]
          end
        end
      end
    end
  end
end
