require 'observer'
require_relative '../remote_stat'


class Rosh
  class FileSystem
    module Adapters

      # This is a generic base class for representing file system objects: files,
      # directories, and links.  It implements what's pretty close to Ruby's
      # +File+ class.
      #
      # Objects of this type are Observable and will notify observers with:
      # self, attribute: [changed attribute], old: [old value], new: [new value]
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
            cmd = if current_host.darwin?
              "stat -a #{@path}"
            else
              "stat -c '%X' #{@path}"
            end

            result = current_shell.exec(cmd)

            Time.at(result.to_i)
          end

          def basename(suffix=nil)
            cmd = "basename #{@path}"
            cmd << " #{suffix}" if suffix

            current_shell.exec(cmd).strip
          end

          def chmod(mode_int)
            current_shell.exec("chmod #{mode_int} #{@path}")
          end

          def chown(uid: uid, gid: nil)
            cmd = "chown #{uid}"
            cmd << ":#{gid}" if gid
            cmd < " #{@path}"

            current_shell.exec cmd
          end

          def ctime
            cmd = if current_host.darwin?
              "stat -f '%c' #{@path}"
            else
              "stat -c '%Z' #{@path}"
            end

            result = current_shell.exec(cmd)

            Time.at(result.to_i)
          end

          def delete
            current_shell.exec "rm #{@path}"
          end

          def dirname
            ::File.dirname(@path)
          end
=begin
          def expand_path(dir_string=nil)
            warn 'Not implemented!'
          end
=end
          def extname
            ::File.extname(basename)
          end

=begin
          def fnmatch(pattern, *flags)

          end
=end
          def ftype
            cmd = if current_host.darwin?
              "stat -f '%HT' #{@path}"
            else
              "stat -c '%F' #{@path}"
            end

            current_shell.exec(cmd).strip.downcase
          end

=begin
          def lchmod
            current_shell.exec("chmod #{mode_int} #{@path}")
          end

          def lchown
          end
=end
          def link(new_path)
            current_shell.exec "ln #{@path} #{new_path}"
          end

          def lstat
            current_shell.exec "stat #{@path}"
          end

          def mtime
            cmd = if current_host.darwin?
              "stat -f '%m' #{@path}"
            else
              "stat -c '%Y' #{@path}"
            end

            result = current_shell.exec(cmd)

            Time.at(result.to_i)
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
            cmd = "stat -L -c '"
            cmd << 'dev: %D ino: %i mode: %f nlink: %h uid: %u gid: %g rdev: %t '
            cmd << 'size: %S blksize: %B blocks: %b atime: %X mtime: %Y ctime: %Z'
            cmd << "' #{@path}"
            result = current_shell.exec(cmd)

            stat = RemoteStat.new
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

            stat.dev = "0x#{dev}"
            stat.ino = ino.to_i
            stat.mode = sprintf('%o', mode.to_i(16))
            stat.nlink = nlink.to_i
            stat.uid = uid.to_i
            stat.gid = gid.to_i
            stat.rdev = "0x#{rdev}"
            stat.size = size.to_i
            stat.blksize = blksize.to_i
            stat.blocks = blocks.to_i
            stat.atime = Time.at(atime.to_i)
            stat.mtime = Time.at(mtime.to_i)
            stat.ctime = Time.at(ctime.to_i)

            stat
          end

          def symlink(new_name)
            current_shell.exec("ln -s #{@path} #{new_name}")
          end

          # @return [Boolean] +true+ if the object is a file; +false+ if not.
          def file?
            cmd = "[ -f #{@path} ]"
            current_shell.exec(cmd)

            current_shell.last_exit_status.zero?
          end

          # @return [Boolean] +true+ if the object is a directory; +false+ if not.
          def directory?
            cmd = "[ -d #{@path} ]"
            current_shell.exec(cmd)

            current_shell.last_exit_status.zero?
          end

          # @return [Boolean] +true+ if the object is a link; +false+ if not.
          def link?
            cmd = "[ -L #{@path} ]"
            current_shell.exec(cmd)

            current_shell.last_exit_status.zero?
          end

          # @return [Boolean] +true+ if the object exists on the file system;
          #   +false+ if not.
          def exists?
            cmd = "[ -e #{@path} ]"
            current_shell.exec(cmd)

            current_shell.last_exit_status.zero?
          end

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

          # @return [Integer] The mode of the file system object.
          def mode
            cmd = "ls -l #{@path} | awk '{print $1}'"
            letter_mode = current_shell.exec(cmd)

            mode_to_i(letter_mode)
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
=begin

        # Just like Ruby's File#basename, returns the base name of the object.
        #
        # @return [String]
        def basename
          File.basename(@path)
        end
=end

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

          #-------------------------------------------------------------------------
          # Privates
          #-------------------------------------------------------------------------
          private

          # Converts mode as letters ('-rwxr--r--') to numbers (744).  Returns +nil+
          # if it can't determine numbers from +letter_mode+.
          #
          # @param [String] letter_mode
          # @return [Integer]
          def mode_to_i(letter_mode)
            %r[^(?<type>.)(?<user>.{3})(?<group>.{3})(?<others>.{3})] =~ letter_mode.strip

            converter = lambda do |letters|
              value = 0

              letters.chars do |char|
                case char
                when '-' then
                  next
                when 'x' then
                  value += 1
                when 'w' then
                  value += 2
                when 'r' then
                  value += 4
                end
              end

              value.to_s
            end

            if user && group && others
              number_mode = ''
              number_mode << converter.call(user)
              number_mode << converter.call(group)
              number_mode << converter.call(others)

              number_mode.to_i
            else
              nil
            end
          end
        end
=begin
        include Observable

        # @param [String] path Path to the object.
        # @param [String,Symbol] host_name
        # @return [Rosh::Host::FileSystemObjects::RemoteDir,Rosh::Host::FileSystemObjects::RemoteFile,Rosh::Host::FileSystemObjects::RemoteLink]
        def self.create(path, host_name)
          fso = new(path, host_name)

          if fso.directory?
            Rosh::Host::FileSystemObjects::RemoteDir.new(path, host_name)
          elsif fso.file?
            Rosh::Host::FileSystemObjects::RemoteFile.new(path, host_name)
          elsif fso.link?
            Rosh::Host::FileSystemObjects::RemoteLink.new(path, host_name)
          end
        end

        attr_reader :path

        # @param [String] path Path to the remote file system object.
        # @param [String,Symbol] host_name
        def initialize(path, host_name)
          @path = path.strip
          @host_name = host_name
        end

        # Returns the pathname used to create file as a String. Does not normalize
        # the name.
        #
        # @return [String]
        def to_path
          @path
        end
=end
      end
    end
  end
end
