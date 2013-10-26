require 'fileutils'
require_relative 'local_base'


class Rosh
  class FileSystem
    module ObjectAdapters
      class LocalFile
        include LocalBase

        class << self
          def read(length=nil, offset=nil)
            ::File.read(@path, length, offset)
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
end
