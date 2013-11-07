require 'fileutils'
require_relative 'local_base'
require_relative '../../errors'
require_relative '../../shell/private_command_result'


class Rosh
  class FileSystem
    module ObjectAdapters
      module LocalFile
        include LocalBase

        def create(&block)
          result = begin
            f = ::File.open(@path, ::File::CREAT, &block)
            exit_status = 0

            ::File.exists? f
          rescue Errno::ENOENT => ex
            exit_status = 1

            Rosh::ErrorENOENT.new(@path)
          end

          private_result(result, exit_status)
        end

        def read(length=nil, offset=nil)
          result = begin
            contents = ::File.read(@path, length, offset)
            exit_status = 0

            contents
          rescue Errno::ENOENT => ex
            exit_status = 1

            Rosh::ErrorENOENT.new(@path)
          end

          private_result(result, exit_status)
        end

        def readlines(separator)
          result = begin
            contents = ::File.readlines(@path, separator)
            exit_status = 0

            contents
          rescue Errno::ENOENT
            exit_status = 1

            Rosh::ErrorENOENT.new(@path)
          end

          private_result(result, exit_status)
        end

        def copy(destination)
          result = begin
            ::FileUtils.cp(@path, destination)
            exit_status = 0

            true
          rescue Errno::ENOENT
            exit_status = 1

            Rosh::ErrorENOENT.new(@path)
          end

          private_result(result, exit_status)
        end

        def save
          ok = if @unwritten_contents
            ::File.open(@path, 'w') do |f|
              f.write(@unwritten_contents)
            end
          else
            false
          end

          exit_status = ok ? 0 : 1

          private_result(ok, exit_status)
        end

        # Stores +new_contents+ in memory until #save is called.
        #
        # @param [String] new_contents Contents to write to the file on #save.
        def write(new_contents)
          @unwritten_contents = new_contents

          private_result(true, 0)
        end
      end
    end
  end
end
