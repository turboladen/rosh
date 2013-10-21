class Rosh
  class FileSystem
    module Adapters
      module LocalStatMethods
        def <=>(other_file)
          f1 = ::File.new(@path)
          f2 = ::File.new(other_file)

          f1.stat <=> f2.stat
        end

        def blksize
          ::File.stat(@path).blksize
        end

        def blockdev?
          ::File.stat(@path).blockdev?
        end

        def blocks
          ::File.stat(@path).blocks
        end

        def chardev?
          ::File.stat(@path).chardev?
        end

        def dev
          ::File.stat(@path).dev
        end

        def dev_major
          ::File.stat(@path).dev_major
        end

        def dev_minor
          ::File.stat(@path).dev_minor
        end

        def directory?
          ::File.directory? @path
        end

        def executable?
          ::File.executable? @path
        end

        def executable_real?
          ::File.executable_real? @path
        end

        def file?
          ::File.file? @path
        end

        def gid
          ::File.stat(@path).gid
        end

        def grpowned?
          ::File.stat(@path).grpowned?
        end

        # @todo Implement.
=begin
          def initialize_copy
            # Implement
          end
=end

        def ino
          ::File.stat(@path).ino
        end

=begin
        def inspect
          ::File.stat(@path).inspect
        end
=end

        def mode
          mode = ::File.stat(@path).mode

          sprintf('%o', mode)
        end

        def nlink
          ::File.stat(@path).nlink
        end

        def owned?
          ::File.stat(@path).owned?
        end

        def pipe?
          ::File.stat(@path).pipe?
        end

        def rdev
          ::File.stat(@path).rdev
        end

        def rdev_major
          ::File.stat(@path).rdev_major
        end

        def rdev_minor
          ::File.stat(@path).rdev_minor
        end

        def readable?
          ::File.stat(@path).readable?
        end

        def readable_real?
          ::File.stat(@path).readable_real?
        end

        def setgid?
          ::File.stat(@path).setgid?
        end

        def setuid?
          ::File.stat(@path).setuid?
        end

        def size
          ::File.size(@path)
        end

        def socket?
          ::File.stat(@path).socket?
        end

        def sticky?
          ::File.stat(@path).sticky?
        end

        def symlink?
          ::File.stat(@path).symlink?
        end

        def uid
          ::File.stat(@path).uid
        end

        def world_readable?
          ::File.stat(@path).world_readable?
        end

        def world_writable?
          ::File.stat(@path).world_writable?
        end

        def writable?
          ::File.stat(@path).writable?
        end

        def writable_real?
          ::File.stat(@path).writable_real?
        end

        def zero?
          ::File.stat(@path).zero?
        end
      end
    end
  end
end
