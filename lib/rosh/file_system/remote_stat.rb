class Rosh
  class FileSystem
    class RemoteStat

      CMD = %q[stat -L -c ] +
        %['dev: %D ino: %i mode: %f nlink: %h uid: %u gid: %g rdev: %t ] +
        %[size: %S blksize: %B blocks: %b atime: %X mtime: %Y ctime: %Z']

      def self.stat(path, host_name)
        @host_name = host_name
        result = current_shell.exec("#{CMD} #{path}")

        new(result, @host_name)
      end

      attr_reader :dev, :ino, :mode, :nlink, :uid, :gid, :rdev, :size, :blksize,
        :blocks, :atime, :mtime, :ctime

      def initialize(result, host_name)
        @host_name = host_name
        parse_result(result)
      end

      private

      def parse_result(result)
        %r[dev: (?<dev>\S+)] =~ result
        %r[ino: (?<ino>\S+)] =~ result
        %r[mode: (?<mode>\S+)] =~ result
        %r[nlink: (?<nlink>\S+)] =~ result
        %r[uid: (?<uid>\S+)] =~ result
        %r[gid: (?<gid>\S+)] =~ result
        %r[rdev: (?<rdev>\S+)] =~ result
        %r[size: (?<size>\S+)] =~ result
        %r[blksize: (?<blksize>\S+)] =~ result
        %r[blocks: (?<blocks>\S+)] =~ result
        %r[atime: (?<atime>\S+)] =~ result
        %r[mtime: (?<mtime>\S+)] =~ result
        %r[ctime: (?<ctime>\S+)] =~ result

        @dev = "0x#{dev}"
        @ino = ino.to_i
        @mode = sprintf('%o', mode.to_i(16))
        @nlink = nlink.to_i
        @uid = uid.to_i
        @gid = gid.to_i
        @rdev = "0x#{rdev}"
        @size = size.to_i
        @blksize = blksize.to_i
        @blocks = blocks.to_i
        @atime = Time.at(atime.to_i)
        @mtime = Time.at(mtime.to_i)
        @ctime = Time.at(ctime.to_i)
      end
    end
  end
end
