require 'forwardable'

class Rosh
  class FileSystem
    module StatController
      extend Forwardable

      def_delegators :adapter,
        :exists?, :<=>,
        :blksize, :blockdev?, :blocks, :chardev?, :dev, :dev_major, :dev_minor,
        :directory?, :executable?, :executable_real?, :file?, :gid, :grpowned?,
        :ino, :mode, :nlink, :owned?, :pipe?,
        :rdev, :rdev_major, :rdev_minor,
        :readable?, :readable_real?,
        :setgid?, :setuid?,
        :size,
        :socket?, :sticky?, :symlink?, :uid,
        :world_readable?, :world_writable?, :writable?, :writable_real?,
        :zero?
    end
  end
end
