require 'fileutils'
require_relative 'local_base'
require_relative '../../errors'


class Rosh
  class FileSystem
    module ObjectAdapters
      module LocalFile
        include LocalBase

        def create(&block)
          f = ::File.open(@path, ::File::CREAT, &block)

          ::File.exists? f
        end

        def read(length=nil, offset=nil)
          begin
            ::File.read(@path, length, offset)
          rescue Errno::ENOENT => ex
            raise Rosh::ErrorENOENT, ex
          end
        end

        def readlines(separator)
          ::File.readlines(@path, separator)
        end

        def copy(destination)
          result = ::FileUtils.cp(@path, destination)

          result.nil?
        end
      end
    end
  end
end
