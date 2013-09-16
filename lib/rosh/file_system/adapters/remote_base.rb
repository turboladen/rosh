require_relative '../remote_stat'


class Rosh
  class FileSystem
    module Adapters

      # This is a generic base class for representing file system objects: files,
      # directories, and links.  It implements what's pretty close to Ruby's
      # +File+ class.
      #
      # When serializing (i.e. dumping to YAML), it maintains only the path to the
      # object.
      module RemoteBase
        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          def path=(path)
            @path = path
          end

          def host_name=(host_name)
            @host_name = host_name
          end

          # @todo Do something with the block.
          def create(&block)
            current_shell.exec "touch #{@path}"
          end

          def absolute_path(dir_string=nil)
            warn 'Not implemented!'
          end

          def atime
            RemoteStat.stat(@path, @host_name).atime
          end

          def basename(suffix=nil)
            cmd = "basename #{@path}"
            cmd << " #{suffix}" if suffix

            current_shell.exec(cmd).strip
          end

          def chmod(mode_int)
            current_shell.exec("chmod #{mode_int} #{@path}")
          end

          def chown(uid, gid=nil)
            cmd = "chown #{uid}"
            cmd << ":#{gid}" if gid
            cmd < " #{@path}"

            current_shell.exec cmd
          end

          def ctime
            RemoteStat.stat(@path, @host_name).ctime
          end

          def delete
            current_shell.exec "rm #{@path}"
          end

          def dirname
            ::File.dirname(@path)
          end

          def expand_path(dir_string=nil)
            if current_host.darwin?
              warn 'Not implemented'
            else
              cmd = "readlink -f #{@path}"
              current_shell.exec(cmd).strip
            end
          end

          def extname
            ::File.extname(basename)
          end

          # @todo Implement.
          def fnmatch(pattern, *flags)
            warn 'Not implemented'
          end

          def ftype
            cmd = if current_host.darwin?
              "stat -n -f '%HT' #{@path}"
            else
              "stat -c '%F' #{@path}"
            end

            current_shell.exec(cmd).strip.downcase
          end

          def lchmod(mode_int)
            current_shell.exec("chmod -h #{mode_int} #{@path}")
          end

          def lchown(uid, gid=nil)
            cmd = "chown -h #{uid}"
            cmd << ":#{gid}" if gid
            cmd < " #{@path}"

            current_shell.exec cmd
          end

          def link(new_path)
            current_shell.exec "ln #{@path} #{new_path}"
          end

          def lstat
            current_shell.exec "stat #{@path}"
          end

          def mtime
            RemoteStat.stat(@path, @host_name).mtime
          end

          def path
            @path
          end

          def readlink
            current_shell.exec("readlink #{@path}").strip
          end

          # @todo Use +dir_path+
          def realdirpath(dir_path=nil)
            current_shell.exec("readlink -f #{dirname}").strip
          end

          def realpath
            current_shell.exec("readlink -f #{@path}").strip
          end

          def rename(new_name)
            current_shell.exec("mv #{@path} #{new_name}")
          end

          def split
            ::File.split(@path)
          end

          def to_path
            @path
          end

          def stat
            RemoteStat.stat(@path, @host_name)
          end

          def symlink(new_name)
            current_shell.exec("ln -s #{@path} #{new_name}")
          end

          def truncate(len)
            current_shell.exec("head --bytes=#{len} --silent #{@path} > #{@path}")
          end

          def utime(access_time, modification_time)
            atime_cmd = "touch -a --no-create --date=#{access_time}"
            mtime_cmd = "touch -m --no-create --date=#{modification_time}"

            current_shell.exec(atime_cmd)
            atime_ok = current_shell.last_exit_status.zero?

            current_shell.exec(mtime_cmd)
            mtime_ok = current_shell.last_exit_status.zero?

            (atime_ok && mtime_ok) ? 1 : 0
          end


          # @return [Boolean] +true+ if the object exists on the file system;
          #   +false+ if not.
          def exists?
            cmd = "[ -e #{@path} ]"
            current_shell.exec(cmd)

            current_shell.last_exit_status.zero?
          end

          #--------------------------------------------------------------------
          # Stat methods
          #--------------------------------------------------------------------

          def <=>(other_file)
            other_object = FileSystem.create(other_file)

            mtime <=> other_object.mtime
          end

          def blksize
            RemoteStat.stat(@path, @host_name).blksize
          end

          def blockdev?
            RemoteStat.blockdev?(@path, @host_name)
          end

          def blocks
            RemoteStat.stat(@path, @host_name).blocks
          end

          def chardev?
            RemoteStat.chardev?(@path, @host_name)
          end

          def dev
            RemoteStat.stat(@path, @host_name).dev
          end

          def dev_major
            RemoteStat.dev_major(@path, @host_name)
          end

          def dev_minor
            RemoteStat.dev_minor(@path, @host_name)
          end

          # @return [Boolean] +true+ if the object is a directory; +false+ if not.
          def directory?
            RemoteStat.directory?(@path, @host_name)
          end

          def executable?
            RemoteStat.executable?(@path, @host_name)
          end

=begin
          def executable_real?

          end
=end

          # @return [Boolean] +true+ if the object is a file; +false+ if not.
          def file?
            RemoteStat.file?(@path, @host_name)
          end

          def gid
            RemoteStat.stat(@path, @host_name).gid
          end

          def grpowned?
            RemoteStat.grpowned?(@path, @host_name)
          end

          def ino
            RemoteStat.stat(@path, @host_name).ino
          end

          def mode
            RemoteStat.stat(@path, @host_name).mode
          end

          def nlink
            RemoteStat.stat(@path, @host_name).nlink
          end

          def owned?
            RemoteStat.owned?(@path, @host_name)
          end

=begin
          # @return [String] The owner of the file system object.
          def owner
            cmd = "ls -l #{@path} | awk '{print $3}'"

            current_shell.exec(cmd).strip
          end

          # Sets the file system object to +new_owner+.  If the update was a
          # success, the shell's #last_exit_status will be 0, which will be the case
          # even if the owner was set to the same owner.  If the update changes the
          # file system object, the observer's #update method gets called.
          #
          # @param [String] new_owner The user name to make the new owner of the file
          #   system object.
          def owner=(new_owner)
            old_owner = owner
            return if current_shell.check_state_first? && old_owner == new_owner

            cmd = "chown #{new_owner} #{@path}"
            current_shell.exec(cmd)

            if current_shell.last_exit_status.zero? && old_owner != new_owner
              changed
              notify_observers(self,
                attribute: :owner, old: old_owner, new: new_owner,
                as_sudo: current_shell.su?)
            end
          end
=end

          def pipe?
            RemoteStat.pipe?(@path, @host_name)
          end

          def rdev
            RemoteStat.stat(@path, @host_name).rdev
          end

          def rdev_major
            RemoteStat.dev_major(@path, @host_name)
          end

          def rdev_minor
            RemoteStat.dev_minor(@path, @host_name)
          end

          def readable?
            RemoteStat.readable?(@path, @host_name)
          end

=begin
          def readable_real?

          end
=end

          def setgid?
            RemoteStat.setgid?(@path, @host_name)
          end

          def setuid?
            RemoteStat.setuid?(@path, @host_name)
          end

          def size
            RemoteStat.stat(@path, @host_name).size
          end

          def socket?
            RemoteStat.socket?(@path, @host_name)
          end

          def sticky?
            RemoteStat.sticky?(@path, @host_name)
          end

          def symlink?
            RemoteStat.symlink?(@path, @host_name)
          end

          def uid
            RemoteStat.stat(@path, @host_name).uid
          end

          def world_readable?
            cmd = if current_host.darwin?
              "stat -f '%Sp' #{@path} | grep 'r\\S\\S$'"
            else
              "stat -c '%A' #{@path} | grep 'r\\S\\S$'"
            end

            current_shell.exec(cmd)

            current_shell.last_exit_status.zero?
          end

          def world_writable?
            cmd = if current_host.darwin?
              "stat -f '%Sp' #{@path} | grep 'w\\S$'"
            else
              "stat -c '%A' #{@path} | grep 'w\\S$'"
            end

            current_shell.exec(cmd)

            current_shell.last_exit_status.zero?
          end

          def writable?
            RemoteStat.writable?(@path, @host_name)
          end

=begin
          def writable_real?
          end
=end

          def zero?
            RemoteStat.zero?(@path, @host_name)
          end

          # @return [String] The group of the file system object.
          def group
            cmd = "ls -l #{@path} | awk '{print $4}'"

            current_shell.exec(cmd).strip
          end

          # Sets the group on the file system object to +new_group+.  If the update was a
          # success, the shell's #last_exit_status will be 0, which will be the case
          # even if the group was set to the same group.  If the update changes the
          # file system object, the observer's #update method gets called.
          #
          # @param [String] new_group The group name to make the new group of the file
          #   system object.
          def group=(new_group)
            old_group = group
            return if current_shell.check_state_first? && old_group == new_group

            cmd = "chgrp #{new_group} #{@path}"
            current_shell.exec(cmd)

            if current_shell.last_exit_status.zero? && old_group != new_group
              changed
              notify_observers(self,
                attribute: :group, old: old_group, new: new_group,
                as_sudo: current_shell.su?)
            end
          end

          # Sets the mode on the file system object to +new_mode+.  If the update was a
          # success, the shell's #last_exit_status will be 0, which will be the case
          # even if the mode was set to the same mode.  If the update changes the
          # file system object, the observer's #update method gets called.
          #
          # @param [Integer] new_mode The mode to set on the file
          #   system object.
          def mode=(new_mode)
            old_mode = mode
            return if current_shell.check_state_first? && old_mode == new_mode

            cmd = "chmod #{new_mode} #{@path}"
            current_shell.exec(cmd)

            if current_shell.last_exit_status.zero? && old_mode != new_mode.to_i
              changed
              notify_observers(self,
                attribute: :mode, old: old_mode, new: new_mode,
                as_sudo: current_shell.su?)
            end
          end

          # Removes the file system object from the remote host.  If the removal was
          # successful, the shell's #last_exit_status will be 0, which will be the
          # case if the file didn't exist before making the call.  If the removal
          # actually removes the object, the observer's #update method gets called.
          def remove
            existed = exists?
            return if current_shell.check_state_first? && !existed

            cmd = "rm -rf #{@path}"
            current_shell.exec(cmd)

            success = current_shell.last_exit_status.zero?

            if success && existed
              changed
              notify_observers(self,
                attribute: :path, old: @path, new: nil,
                as_sudo: current_shell.su?)
            end

            success
          end

          # Called by serializer when dumping.
=begin
        def encode_with(coder)
          coder['path'] = @path
          coder['host_name'] = @host_name
        end

        # Called by serializer when loading.
        def init_with(coder)
          @path = coder['path']
          @host_name = coder['host_name']
        end
=end
        end
      end
    end
  end
end
