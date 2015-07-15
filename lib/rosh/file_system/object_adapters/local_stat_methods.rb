class Rosh
  class FileSystem
    module ObjectAdapters
      module LocalStatMethods
        def <=>(other_file)
          handle_errors_and_return_result do
            f1 = ::File.new(@path)
            f2 = ::File.new(other_file)

            f1.stat <=> f2.stat
          end
        end

        def blksize
          handle_errors_and_return_result { ::File.stat(@path).blksize }
        end

        def blockdev?
          handle_errors_and_return_result { ::File.stat(@path).blockdev? }
        end

        def blocks
          handle_errors_and_return_result { ::File.stat(@path).blocks }
        end

        def chardev?
          handle_errors_and_return_result { ::File.stat(@path).chardev? }
        end

        def dev
          handle_errors_and_return_result { ::File.stat(@path).dev }
        end

        def dev_major
          handle_errors_and_return_result { ::File.stat(@path).dev_major }
        end

        def dev_minor
          handle_errors_and_return_result { ::File.stat(@path).dev_minor }
        end

        def directory?
          handle_errors_and_return_result { ::File.directory? @path }
        end

        def executable?
          handle_errors_and_return_result { ::File.executable? @path }
        end

        def executable_real?
          handle_errors_and_return_result { ::File.executable_real? @path }
        end

        def file?
          handle_errors_and_return_result { ::File.file? @path }
        end

        def gid
          handle_errors_and_return_result { ::File.stat(@path).gid }
        end

        def grpowned?
          handle_errors_and_return_result { ::File.stat(@path).grpowned? }
        end

        # @todo Implement.
        #           def initialize_copy
        #             # Implement
        #           end

        def ino
          handle_errors_and_return_result { ::File.stat(@path).ino }
        end

        #         def inspect
        #           ::File.stat(@path).inspect
        #         end

        def mode
          handle_errors_and_return_result do
            mode = ::File.stat(@path).mode

            sprintf('%o', mode)
          end
        end

        def nlink
          handle_errors_and_return_result { ::File.stat(@path).nlink }
        end

        def owned?
          handle_errors_and_return_result { ::File.stat(@path).owned? }
        end

        def pipe?
          handle_errors_and_return_result { ::File.stat(@path).pipe? }
        end

        def rdev
          handle_errors_and_return_result { ::File.stat(@path).rdev }
        end

        def rdev_major
          handle_errors_and_return_result { ::File.stat(@path).rdev_major }
        end

        def rdev_minor
          handle_errors_and_return_result { ::File.stat(@path).rdev_minor }
        end

        def readable?
          handle_errors_and_return_result { ::File.stat(@path).readable? }
        end

        def readable_real?
          handle_errors_and_return_result { ::File.stat(@path).readable_real? }
        end

        def setgid?
          handle_errors_and_return_result { ::File.stat(@path).setgid? }
        end

        def setuid?
          handle_errors_and_return_result { ::File.stat(@path).setuid? }
        end

        def size
          handle_errors_and_return_result { ::File.size(@path) }
        end

        def socket?
          handle_errors_and_return_result { ::File.stat(@path).socket? }
        end

        def sticky?
          handle_errors_and_return_result { ::File.stat(@path).sticky? }
        end

        def symlink?
          handle_errors_and_return_result { ::File.stat(@path).symlink? }
        end

        def uid
          handle_errors_and_return_result { ::File.stat(@path).uid }
        end

        def world_readable?
          handle_errors_and_return_result { ::File.stat(@path).world_readable? }
        end

        def world_writable?
          handle_errors_and_return_result { ::File.stat(@path).world_writable? }
        end

        def writable?
          handle_errors_and_return_result { ::File.stat(@path).writable? }
        end

        def writable_real?
          handle_errors_and_return_result { ::File.stat(@path).writable_real? }
        end

        def zero?
          handle_errors_and_return_result { ::File.stat(@path).zero? }
        end
      end
    end
  end
end
