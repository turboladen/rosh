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
        run(path, host_name) do
          result = if current_host.darwin?
            current_shell.exec("#{OSX_CMD} #{path}")
          else
            current_shell.exec("#{LINUX_CMD} #{path}")
          end

          new(result, host_name)
        end
      end

      def self.blockdev?(path, host_name)
        run(path, host_name) do
          cmd = "[ -b #{path} ]"
          current_shell.exec(cmd)

          current_shell.last_exit_status.zero?
        end
      end

      def self.chardev?(path, host_name)
        run(path, host_name) do
          cmd = "[ -c #{path} ]"
          current_shell.exec(cmd)

          current_shell.last_exit_status.zero?
        end
      end

      def self.dev_major(path, host_name)
        run(path, host_name) do
          cmd = if current_host.darwin?
            "stat -n -f '%Hr' #{path}"
          else
            "stat -c '%t' #{path}"
          end

          current_shell.exec(cmd).strip.to_i
        end
      end

      def self.dev_minor(path, host_name)
        run(path, host_name) do
          cmd = if current_host.darwin?
            "stat -n -f '%Lr' #{path}"
          else
            "stat -c '%T' #{path}"
          end

          current_shell.exec(cmd).strip.to_i
        end
      end

      def self.directory?(path, host_name)
        run(path, host_name) do
          cmd = "[ -d #{path} ]"
          current_shell.exec(cmd)

          current_shell.last_exit_status.zero?
        end
      end

      def self.executable?(path, host_name)
        run(path, host_name) do
          cmd = "[ -x #{path} ]"
          current_shell.exec(cmd)

          current_shell.last_exit_status.zero?
        end
      end

      def self.file?(path, host_name)
        run(path, host_name) do
          cmd = "[ -f #{path} ]"
          current_shell.exec(cmd)

          current_shell.last_exit_status.zero?
        end
      end

      def self.grpowned?(path, host_name)
        run(path, host_name) do
          cmd = "[ -G #{path} ]"
          current_shell.exec(cmd)

          current_shell.last_exit_status.zero?
        end
      end

      def self.owned?(path, host_name)
        run(path, host_name) do
          cmd = "[ -O #{path} ]"
          current_shell.exec(cmd)

          current_shell.last_exit_status.zero?
        end
      end

      def self.pipe?(path, host_name)
        run(path, host_name) do
          cmd = "[ -p #{path} ]"
          current_shell.exec(cmd)

          current_shell.last_exit_status.zero?
        end
      end

      def self.readable?(path, host_name)
        run(path, host_name) do
          cmd = "[ -r #{path} ]"
          current_shell.exec(cmd)

          current_shell.last_exit_status.zero?
        end
      end

      def self.setgid?(path, host_name)
        run(path, host_name) do
          cmd = "[ -g #{path} ]"
          current_shell.exec(cmd)

          current_shell.last_exit_status.zero?
        end
      end

      def self.setuid?(path, host_name)
        run(path, host_name) do
          cmd = "[ -u #{path} ]"
          current_shell.exec(cmd)

          current_shell.last_exit_status.zero?
        end
      end

      def self.socket?(path, host_name)
        run(path, host_name) do
          cmd = "[ -S #{path} ]"
          current_shell.exec(cmd)

          current_shell.last_exit_status.zero?
        end
      end

      def self.sticky?(path, host_name)
        run(path, host_name) do
          cmd = "[ -k #{path} ]"
          current_shell.exec(cmd)

          current_shell.last_exit_status.zero?
        end
      end

      def self.symlink?(path, host_name)
        run(path, host_name) do
          cmd = "[ -L #{path} ]"
          current_shell.exec(cmd)

          current_shell.last_exit_status.zero?
        end
      end

      def self.writable?(path, host_name)
        run(path, host_name) do
          cmd = "[ -w #{path} ]"
          current_shell.exec(cmd)

          current_shell.last_exit_status.zero?
        end
      end

      def self.zero?(path, host_name)
        run(path, host_name) do
          cmd = "[ -s #{path} ]"
          current_shell.exec(cmd)

          !current_shell.last_exit_status.zero?
        end
      end

      #------------------------------------------------------------------------
      # Class Privates
      #------------------------------------------------------------------------
      private

      def self.run(path, host_name, &block)
        @host_name = host_name

        block.call(path)
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
        @mode = current_host.darwin? ? mode : sprintf('%o', mode.to_i(16))
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
