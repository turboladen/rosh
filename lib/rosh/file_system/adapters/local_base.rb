require 'etc'


class Rosh
  class FileSystem
    module Adapters

      # Base class for local file system objects.  Simply, it provides for
      # delegating to built-in Ruby Dir and File methods.
      module LocalBase
        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          def path=(path)
            @path = path
          end

          # Returns the pathname used to create file as a String. Does not normalize
          # the name.
          #
          # @return [String]
          def to_path
            @path
          end

          # @param [String] dir_string
          def absolute_path(dir_string=nil)
            ::File.absolute_path(@path, dir_string)
          end

          def atime
            ::File.atime(@path)
          end

          # Just like Ruby's File#basename, returns the base name of the object.
          #
          # @param [String] suffix
          # @return [String]
          def basename(suffix=nil)
            if suffix
              ::File.basename(@path, suffix)
            else
              ::File.basename(@path)
            end
          end

          def chmod(mode_int)
            ::File.chmod(mode_int, @path)
          end

          # Allows setting user/group owner using key/value pairs.  If no value is
          # given for user or group, nothing will be changed.
          #
          # @param [String] :user_name Name of the user to make owner.
          # @param [Fixnum] :uid UID of the user to make owner.
          # @param [String] :group_name Name of the group to make owner.
          # @param [Fixnum] :gid GID of the group to make owner.
          # @return [0]
          def chown(uid: nil, gid: nil)
            ::File.chown(uid, gid, @path)
          end

          def ctime
            ::File.ctime(@path)
          end

          def delete
            ::File.delete(@path)
          end

          def expand_path(dir_string=nil)
            ::File.expand_path(@path, dir_string)
          end

          def extname
            ::File.extname(@path)
          end

          def fnmatch(pattern, *flags)
            ::File.fnmatch(pattern, @path, *flags)
          end
          alias_method :fnmatch?, :fnmatch

          def ftype
            ::File.ftype(path)
          end

          def lchmod(mode_int)
            ::File.lchmod(mode_int, @path)
          end

          def lchown(new_uid: nil, new_gid: nil)
            ::File.lchown(new_uid, new_gid, @path)
          end

          def link(new_path)
            ::File.link(@path, new_path)
          end

          def lstat
            ::File.lstat(@path)
          end

          def mtime
            ::File.mtime(@path)
          end

=begin
        def open(mode, *options, &block)
          File.open(@path, options, block)
        end
=end

          def path
            ::File.path(@path)
          end

          def readlink
            ::File.readlink(@path)
          end

          def realdirpath(dir_path=nil)
            ::File.realdirpath(@path, dir_path)
          end

          def real_path(dir_path=nil)
            ::File.realpath(@path, dir_path)
          end

          def rename(new_name)
            ::File.rename(@path, new_name)
          end

          def split
            ::File.split(@path)
          end

          def stat
            ::File.stat(@path)
          end

          def symlink(new_name)
            ::File.symlink(@path, new_name)
          end

          def truncate(len)
            ::File.truncate(@path, len)
          end

          def utime(access_time, modification_time)
            ::File.utime(access_time, modification_time, @path)
          end

          # @todo Implement.
          def flock
            # Implement
          end

          def exists?
            ::File.exists? @path
          end

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
          def initialize_copy
            # Implement
          end

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

          # Wrapper for #chown that allows setting user/group owner using key/value
          # pairs.  If no value is given for user or group, nothing will be changed.
          #
          # @param [Hash] options
          # @option options [String] :user_name Name of the user to make owner.
          # @option options [Fixnum] :uid UID of the user to make owner.
          # @option options [String] :group_name Name of the group to make owner.
          # @option options [Fixnum] :gid GID of the group to make owner.
          # @return [Hash{:user => Struct::Passwd, :group => Struct::Group}] The
          #   owning user and group of the file system object.
          def owner(**options)
            if options.empty?
              return {
                user: Etc.getpwuid(stat.uid),
                group: Etc.getgrgid(stat.gid)
              }
            end

            uid = extract_uid(options)
            gid = extract_gid(options)

            if chown(uid, gid) == 1
              {
                user: Etc.getpwuid(stat.uid),
                group: Etc.getgrgid(stat.gid)
              }
            else
              raise "Unable to chown using uid '#{uid}' and gid '#{gid}'."
            end
          end


=begin
        # @return [Struct::Group]
        def group
          Etc.getgrgid(stat.gid)
        end

        # @return [String] The basename of the path.
        def to_s
          File.basename @path
        end
=end

          private

          # If :user_name is given, it gets the UID for that user, otherwise just
          # returns :user_uid.
          #
          # @param [Hash] options
          # @return [Fixnum] the UID.
          def extract_uid(options)
            if options[:user_name]
              user = Etc.getpwnam(options[:user_name])
              user.uid
            elsif options[:uid]
              options[:uid].to_i
            end
          end

          # If :group_name is given, it gets the GID for that group, otherwise just
          # returns :gid.
          #
          # @param [Hash] options
          # @return [Fixnum] the GID.
          def extract_gid(options)
            if options[:group_name]
              group = Etc.getgrnam(options[:group_name])
              group.gid
            elsif options[:gid]
              options[:gid].to_i
            end
          end
        end
      end
    end
  end
end
