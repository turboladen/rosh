class Rosh
  class FileSystem
    class RemoteStat

      LINUX_CMD = %q[stat -L -c ] +
        %['dev: %D ino: %i mode: %f nlink: %h uid: %u gid: %g rdev: %t ] +
        %[size: %S blksize: %B blocks: %b atime: %X mtime: %Y ctime: %Z']

      OSX_CMD = %q[stat -n -f ] +
        %['dev: %d ino: %i mode: %p nlink: %l uid: %u gid: %g rdev: %r ] +
        %[size: %z blksize: %k blocks: %b atime: %a mtime: %m ctime: %c']

      def self.stat(path, host_name)
        @host_name = host_name
        result = if current_host.darwin?
          current_shell.exec("#{OSX_CMD} #{path}")
        else
          current_shell.exec("#{LINUX_CMD} #{path}")
        end

        new(result, @host_name)
      end

      def self.dev_major(path, host_name)
        @host_name = host_name

        cmd = if current_host.darwin?
          "stat -n -f '%Hr' #{path}"
        else
          "stat -c '%t' #{path}"
        end

        current_shell.exec(cmd)
      end

      def self.dev_minor(path, host_name)
        @host_name = host_name

        cmd = if current_host.darwin?
          "stat -n -f '%Lr' #{path}"
        else
          "stat -c '%T' #{path}"
        end

        current_shell.exec(cmd)
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
