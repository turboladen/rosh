class Rosh
  class FileSystem
    class RemoteStat

      LINUX_CMD = %q[stat -L -c ] +
        %['dev: %D ino: %i mode: %f nlink: %h uid: %u gid: %g rdev: %t ] +
        %[size: %s blksize: %B blocks: %b atime: %X mtime: %Y ctime: %Z']

      OSX_CMD = %q[stat -n -f ] +
        %['dev: %d ino: %i mode: %p nlink: %l uid: %u gid: %g rdev: %r ] +
        %[size: %z blksize: %k blocks: %b atime: %a mtime: %m ctime: %c']

      def self.stat(path, host_name)
        run(host_name) do |host|
          result = if host.darwin?
            host.shell.exec_internal("#{OSX_CMD} #{path}")
          else
            host.shell.exec_internal("#{LINUX_CMD} #{path}")
          end

          new(result.string, host.name)
        end
      end

      def self.blockdev?(path, host_name)
        run(host_name) do |host|
          cmd = "test -b #{path}"
          host.shell.exec_internal(cmd)

          host.shell.last_exit_status.zero?
        end
      end

      def self.chardev?(path, host_name)
        run(host_name) do |host|
          cmd = "test -c #{path}"
          host.shell.exec_internal(cmd)

          host.shell.last_exit_status.zero?
        end
      end

      def self.dev_major(path, host_name)
        run(host_name) do |host|
          cmd = if host.darwin?
            "stat -n -f '%Hr' #{path}"
          else
            "stat -c '%t' #{path}"
          end

          host.shell.exec_internal(cmd).string.strip.to_i
        end
      end

      def self.dev_minor(path, host_name)
        run(host_name) do |host|
          cmd = if host.darwin?
            "stat -n -f '%Lr' #{path}"
          else
            "stat -c '%T' #{path}"
          end

          host.shell.exec_internal(cmd).string.strip.to_i
        end
      end

      def self.directory?(path, host_name)
        run(host_name) do |host|
          cmd = "test -d #{path}"
          host.shell.exec_internal(cmd)

          host.shell.last_exit_status.zero?
        end
      end

      def self.executable?(path, host_name)
        run(host_name) do |host|
          cmd = "test -x #{path}"
          host.shell.exec_internal(cmd)

          host.shell.last_exit_status.zero?
        end
      end

      # TODO: Is this right?
      def self.executable_real?(path, host_name)
        executable?(path, host_name)
      end

      def self.file?(path, host_name)
        run(host_name) do |host|
          cmd = "test -f #{path}"
          host.shell.exec_internal(cmd)

          host.shell.last_exit_status.zero?
        end
      end

      def self.grpowned?(path, host_name)
        run(host_name) do |host|
          cmd = "test -G #{path}"
          host.shell.exec_internal(cmd)

          host.shell.last_exit_status.zero?
        end
      end

      def self.owned?(path, host_name)
        run(host_name) do |host|
          cmd = "test -O #{path}"
          host.shell.exec_internal(cmd)

          host.shell.last_exit_status.zero?
        end
      end

      def self.pipe?(path, host_name)
        run(host_name) do |host|
          cmd = "test -p #{path}"
          host.shell.exec_internal(cmd)

          host.shell.last_exit_status.zero?
        end
      end

      def self.readable?(path, host_name)
        run(host_name) do |host|
          cmd = "test -r #{path}"
          host.shell.exec_internal(cmd)

          host.shell.last_exit_status.zero?
        end
      end

      # TODO: Is this right?
      def self.readable_real?(path, host_name)
        readable?(path, host_name)
      end

      def self.setgid?(path, host_name)
        run(host_name) do |host|
          cmd = "test -g #{path}"
          host.shell.exec_internal(cmd)

          host.shell.last_exit_status.zero?
        end
      end

      def self.setuid?(path, host_name)
        run(host_name) do |host|
          cmd = "test -u #{path}"
          host.shell.exec_internal(cmd)

          host.shell.last_exit_status.zero?
        end
      end

      def self.socket?(path, host_name)
        run(host_name) do |host|
          cmd = "test -S #{path}"
          host.shell.exec_internal(cmd)

          host.shell.last_exit_status.zero?
        end
      end

      def self.sticky?(path, host_name)
        run(host_name) do |host|
          cmd = "test -k #{path}"
          host.shell.exec_internal(cmd)

          host.shell.last_exit_status.zero?
        end
      end

      def self.symlink?(path, host_name)
        run(host_name) do |host|
          cmd = "test -L #{path}"
          host.shell.exec_internal(cmd)

          host.shell.last_exit_status.zero?
        end
      end

      def self.writable?(path, host_name)
        run(host_name) do |host|
          cmd = "test -w #{path}"
          host.shell.exec_internal(cmd)

          host.shell.last_exit_status.zero?
        end
      end

      def self.writable_real?(path, host_name)
        writable?(path, host_name)
      end

      def self.zero?(path, host_name)
        run(host_name) do |host|
          cmd = "test -s #{path}"
          host.shell.exec_internal(cmd)

          !host.shell.last_exit_status.zero?
        end
      end

      #------------------------------------------------------------------------
      # Class Privates
      #------------------------------------------------------------------------
      private

      def self.run(host_name, &block)
        host = Rosh.find_by_host_name(host_name)

        yield host
      end

      #------------------------------------------------------------------------
      # Instance Publics
      #------------------------------------------------------------------------
      public

      attr_reader :dev, :ino, :mode, :nlink, :uid, :gid, :rdev, :size, :blksize,
        :blocks, :atime, :mtime, :ctime

      def initialize(result, host_name)
        @host_name = host_name
        parse_result(result)
      end

      def host
        Rosh.find_by_host_name(@host_name)
      end

      #------------------------------------------------------------------------
      # Instance Privates
      #------------------------------------------------------------------------
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
        @mode = host.darwin? ? mode : sprintf('%o', mode.to_i(16))
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
