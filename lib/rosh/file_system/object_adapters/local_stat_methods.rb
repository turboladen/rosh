class Rosh
  class FileSystem
    module ObjectAdapters
      module LocalStatMethods
        def <=>(other_file)
          f1 = ::File.new(@path)
          f2 = ::File.new(other_file)

          f1.stat <=> f2.stat
        end

        def blksize
          process { ::File.stat(@path).blksize }
        end

        def blockdev?
          process { ::File.stat(@path).blockdev? }
        end

        def blocks
          process { ::File.stat(@path).blocks }
        end

        def chardev?
          process { ::File.stat(@path).chardev? }
        end

        def dev
          process { ::File.stat(@path).dev }
        end

        def dev_major
          process { ::File.stat(@path).dev_major }
        end

        def dev_minor
          process { ::File.stat(@path).dev_minor }
        end

        def directory?
          process { ::File.directory? @path }
        end

        def executable?
          process { ::File.executable? @path }
        end

        def executable_real?
          process { ::File.executable_real? @path }
        end

        def file?
          process { ::File.file? @path }
        end

        def gid
          process { ::File.stat(@path).gid }
        end

        def grpowned?
          process { ::File.stat(@path).grpowned? }
        end

        # @todo Implement.
=begin
          def initialize_copy
            # Implement
          end
=end

        def ino
          process { ::File.stat(@path).ino }
        end

=begin
        def inspect
          ::File.stat(@path).inspect
        end
=end

        def mode
          process do
            mode = ::File.stat(@path).mode

            sprintf('%o', mode)
          end
        end

        def nlink
          process { ::File.stat(@path).nlink }
        end

        def owned?
          process { ::File.stat(@path).owned? }
        end

        def pipe?
          process { ::File.stat(@path).pipe? }
        end

        def rdev
          process { ::File.stat(@path).rdev }
        end

        def rdev_major
          process { ::File.stat(@path).rdev_major }
        end

        def rdev_minor
          process { ::File.stat(@path).rdev_minor }
        end

        def readable?
          process { ::File.stat(@path).readable? }
        end

        def readable_real?
          process { ::File.stat(@path).readable_real? }
        end

        def setgid?
          process { ::File.stat(@path).setgid? }
        end

        def setuid?
          process { ::File.stat(@path).setuid? }
        end

        def size
          process { ::File.size(@path) }
        end

        def socket?
          process { ::File.stat(@path).socket? }
        end

        def sticky?
          process { ::File.stat(@path).sticky? }
        end

        def symlink?
          process { ::File.stat(@path).symlink? }
        end

        def uid
          process { ::File.stat(@path).uid }
        end

        def world_readable?
          process { ::File.stat(@path).world_readable? }
        end

        def world_writable?
          process { ::File.stat(@path).world_writable? }
        end

        def writable?
          process { ::File.stat(@path).writable? }
        end

        def writable_real?
          process { ::File.stat(@path).writable_real? }
        end

        def zero?
          process { ::File.stat(@path).zero? }
        end

        private

        def process
          result = yield

          private_result(result, 0)
        end
      end
    end
  end
end
